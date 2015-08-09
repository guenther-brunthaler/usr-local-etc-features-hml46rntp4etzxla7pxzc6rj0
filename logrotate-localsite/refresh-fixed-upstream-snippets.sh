#! /bin/sh
basedir=/etc/logrotate-localsite
defaults=$basedir/defaults

set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0

cd "$basedir"
outdir=$basedir/fixed-upstream.d
test -d "$outdir"
rm -rf -- "$outdir"/*
indir=$basedir/ignored-upstream.d
test -d "$indir"
# Most upstream snippets seem to indent by 4 spaces.
inc="    include $defaults"
edscript='
	# Matches the beginning of a local settings block.
	\:^/.*{: {
		p # Print the current pattern space (= the current line).
		# Replace patten space to be printed by $inc.
		s:.*:'"$inc"':
		b # Print pattern space and start cycle.
	}
	# Matches the end of a local settings block.
	/^}/ {
		h # Save current line to hold space.
		# Replace patten space to be printed by $inc.
		s:.*:'"$inc"':
		p # Print it.
		g # Restore current line to be printed next.
	}
'
for s in "$indir"/*
do
	test -e "$s" || continue # Required if upstream.d is empty.
	o=$outdir/${s#"$indir/"}
	echo "Generating '$o'..." >& 2
	sed "$edscript" < "$s" > "$o"
done
