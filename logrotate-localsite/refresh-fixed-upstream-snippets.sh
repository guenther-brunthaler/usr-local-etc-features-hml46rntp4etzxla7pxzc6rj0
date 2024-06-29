#! /bin/sh

# Migrate upstream logrotate-snippets (from <indir>) into ones to be actually
# used (<outdir>) when logrotate is run.
#
# This migration works by inserting "include" commands into the original
# snippets which enforce the local logrotation policy.
#
# Upstream snippets for which snippets of the same name exist in one of the
# <overrides> subdirectories will not be migrated. Those snippets will be
# included directly by the logrotate configuration.
#
# This script can also be run from a cron job if standard error is redirected
# to /dev/null. It only writes to /etc/ when actually necessary and avoids all
# unnecessary write accesses (as long as $TMPDIR or /tmp is a tmpfs or ramfs).
#
# Version 2024.181

basedir=/etc/logrotate-localsite
defaults=$basedir/defaults
overrides='site.d realm.d' # Highest priority first.

set -e
cleanup() {
	rc=$?
	test "$T" && rm -- "$T"
	test $rc = 0 || echo "\"$0\" failed!" >& 2
}
T=
trap cleanup 0

cd -- "$basedir"
outdir=$basedir/fixed-upstream.d
test -d "$outdir"
indir=$basedir/ignored-upstream.d
test -d "$indir"
# Remove already-patched upstream copies which have become obsolete.
for o in "$outdir"/*
do
	test ! -e "$o" && continue # Required if directory is empty.
	ob=${o#"$outdir/"} # Basename of upstream snippet.
	overridden=false
	for ov in $overrides
	do
		if test -e "$basedir/$ov/$ob"
		then
			overridden=true
			break
		fi
	done
	test $overridden = false && test -e "$indir/${o#"$outdir/"}" \
		&& continue
	echo "Removing orphaned '$o'..." >& 2
	rm -- "$o"
done
# Most upstream snippets seem to be indented by 4 spaces.
inc="    include $defaults"
edscript='
	# Matches the beginning of a local settings block.
	\:^/.*{: {
		p # Print the current pattern space (= the current line).
		# Replace pattern space to be printed with $inc.
		s:.*:'"$inc"':
		b # Print pattern space and start next cycle.
	}
	# Matches the end of a local settings block.
	/^}/ {
		h # Save current line to hold space.
		# Replace pattern space with $inc.
		s:.*:'"$inc"':
		p # Print it.
		g # Restore current line to be printed at start of next cycle.
	}
'
T=`mktemp -- "${TMPDIR:-/tmp}/${0##*/}.XXXXXXXXXX"`
# Create patched copies of all upstream snippets unless overrides for them are
# present.
for s in "$indir"/*
do
	test ! -e "$s" && continue # Required if directory is empty.
	ob=${s#"$indir/"} # Basename of upstream snippet.
	for o in $overrides
	do
		test -f "$basedir/$o/$ob" && continue 2 # Override exists.
	done
	o=$outdir/$ob # Pathname of patched copy.
	sed "$edscript" < "$s" > "$T" # Create patched version $T.
	# Avoid overwriting unless necessary to not disturb file mtime and
	# ctime and thus not triggering unnecessary backups.
	if cmp -s -- "$T" "$o"
	then
		:
	else
		echo "Generating '$o'..." >& 2
		cat < "$T" > "$o"
	fi
done
echo "Third-party logrotate snippet site-policy enforcement is up to date." \
	>& 2
