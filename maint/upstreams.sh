# Find all *.upstream files present only in the template directory and where a
# local working file (same name but without the ".upstream"-suffix) exists
# with different contents.
#
# That is, report files which have local modifications against the original
# upstream copies, so it might be a good idea to keep the upstream versions
# also around for comparison.
#
# Typically, both the locally-modified working file and the corresponding
# *.upstream file should be put under version control. Then a "diff" can be
# shown at any time, identifiying the local modifications against the original
# upstream version.
#
# The script also reports local and template *.upstream files which both exist
# but differ. In such cases, at least one of both sides must be outdated, and
# the newest current upstream version should be determined, replacing both
# copies.
#
# Version 2022.9

set -e
trap 'test $? = 0 || echo "\"$0\" failed!" >& 2' 0

while getopts '' opt
do
	case $opt in
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

test $# = 0

base=`readlink -f -- "$0"`
base=`dirname -- "$base"`
base=`dirname -- "$base"`
cd -- "$base" # chdir to base of the template files for /etc.
find . -name "*.upstream" \
| while IFS= read -r tu
do
	tu=${tu#./} # Relative path of template *.upstream file.
	lu=/etc/$tu # Absolute path of local *.upstream file.
	le=${lu%.upstream} # Path of local copy (without the .upstream).
	if test -e "$lu"
	then
		# Both local and template *.upstream files exist.
		if cmp -s "$lu" "$tu"
		then
			# But they are different! At least one of them must be
			# outdated.
			problem=OUTDATED
		elif test ! -e "$le"
		then
			# We have a local *.upstream file without a
			# corresponding local file without the ".upstream"
			# suffix.
			problem=ORPHANED
		elif cmp -s "$le" "$lu"
		then
			# We have both a local *.upstream file and a
			# corresponding local file, but both are identical. It
			# does not seem we need the upstream file any longer,
			# because there are no local modifications.
			problem=USELESS
		else
			# We have both local .upstream and local files and
			# both are different. That is what is to be expected.
			# No problem exists.
			continue
		fi
	else
		# Only template *.upstream file exists.
		if test -e "$le"
		then
			# But a local working file does exists.
			cmp -s "$le" "$tu" && continue # Obviously unmodified.
			# The working file is different from the template
			# upstream version. We should keep a local upstream
			# copy around for documenting the differences!
			problem=MISSING
		else
			# There is neither a local working file nor a local upstream copy.
			# Obviously we do not need such a working copy at all. Fine.
			continue
		fi
	fi
	echo "$problem: $tu"
done
