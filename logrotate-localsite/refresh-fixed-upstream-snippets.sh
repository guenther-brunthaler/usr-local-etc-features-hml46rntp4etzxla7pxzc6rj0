#! /bin/sh
# This script can also be run from a cron job if standard error is redirected
# to /dev/null. It only writes to /etc/ when actually necessary and avoids all
# unnecessary write accesses (as long as $TMPDIR or /tmp is a tmpfs or ramfs).
#
# Version 2018.263

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

cd "$basedir"
outdir=$basedir/fixed-upstream.d
test -d "$outdir"
indir=$basedir/ignored-upstream.d
test -d "$indir"
for o in "$outdir"/*
do
	test -e "$o" || continue # Required if directory is empty.
	ob=${o#"$outdir/"}
	for s in "${indir#"$basedir/"}" $overrides
	do
		s=$basedir/$s/$ob
		test -f "$s" && continue 2
	done
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
for s in "$indir"/*
do
	test -e "$s" || continue # Required if directory is empty.
	ob=${s#"$indir/"}
	none=true
	for o in $overrides
	do
		o=$basedir/$o/$ob
		test ! -f "$o" && continue
		cat < "$o" > "$T"
		none=false
		break
	done
	o=$outdir/$ob
	$none && sed "$edscript" < "$s" > "$T"
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
