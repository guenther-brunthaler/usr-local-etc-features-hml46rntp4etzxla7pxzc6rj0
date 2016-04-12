#! /bin/sh
# This script can also be run from a cron job if standard error is redirected
# to /dev/null. It only writes to /etc/ when actually necessary and avoids all
# unnecessary write accesses (as long as $TMPDIR or /tmp is a tmpfs or ramfs).

basedir=/etc/logrotate-localsite
defaults=$basedir/defaults

set -e
cleanup() {
	local rc=$?
	test -n "$T" && rm -- "$T"
	test $rc = 0 || echo "$0 failed!" >& 2
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
	s=$indir/${o#"$outdir/"}
	test -f "$s" && continue
	echo "Removing orphaned '$o'..." >& 2
	rm -- "$o"
done
# Most upstream snippets seem to indent by 4 spaces.
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
T=`mktemp "${TMPDIR:-/tmp}/${0##*/}.XXXXXXXXXX"`
for s in "$indir"/*
do
	test -e "$s" || continue # Required if directory is empty.
	o=$outdir/${s#"$indir/"}
	sed "$edscript" < "$s" > "$T"
	# Avoid overwriting unless necessary to not disturb file mtime and
	# ctime and thus not triggering unnecessary backups.
	if cmp -s -- "$T" "$o"
	then
		:
	else
		echo "Generating '$o'..." >& 2
		cat "$T" > "$o"
	fi
done
echo "Third-party logrotate snippet site-policy enforcement is up to date." \
	>& 2
