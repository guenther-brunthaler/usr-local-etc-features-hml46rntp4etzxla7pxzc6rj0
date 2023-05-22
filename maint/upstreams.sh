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
# The -a option suggests actions - piping them into a shell will execute them.
# (Diagnostic messages will always be writen to the standard error stream only
# and will therefore not interfere with the suggested commands written to
# standard output.
#
# Version 2022.9.1

# Requires: qin-32r1h6hwy9bst69b8zpw5uqf0
# Requires: show_failures-ci9hjhmyjuy0cx1wmguv7n6h0

# Start (= gllez8xrsremp6jlwifp03krc): {
# Prologue bj2lapzmr8ydaa4jmq66c9kr0:
set -e
base=`readlink -f -- "$0"`
base=`dirname -- "$base"`
base=`dirname -- "$base"`

lib=$base/libexec/lib/sh
# Auto-Generated b83iv5hz8sbpbv4i80t9v5rwv:
. "$lib"/println-871v57a0dzb6d3rxykj87vsnf.sh
. "$lib"/qin-32r1h6hwy9bst69b8zpw5uqf0.sh
. "$lib"/scopes-hqxbfzp9026esereelim9tbyk.sh
. "$lib"/trap_errors-3vnzcvh9hfs134g6ln6cy567k
. "$lib"/show_failures-ci9hjhmyjuy0cx1wmguv7n6h0.sh
# } End (= bw80hxwxxzma2qu0x8b75t2y4)

suggest_action=false
while getopts a opt
do
	case $opt in
		a) suggest_action=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

test $# = 0

# Report that file $2 has problem $1. $3 and on are suggested action, if any.
problem() {
	echo "$1: $2" >& 2
	if $suggest_action && test "${3+set}"
	then
		shift 2
		qin "$@"
	fi
}

# chdir to base of the template files for /etc.
cd -- "$base"

# Return UNIX timestamp of file $2 in Git checkout $1.
git_uxts() {
	(
		cd -- "$1"
		git log -n 1 --pretty=%at -- "$2"
	)
}

# Process all existing template *.upstream files.
find . -name "*.upstream" \
| while IFS= read -r tu
do
	ru=${tu#./} # Relative path of template *.upstream file.
	lu=/etc/$ru # Absolute path of local *.upstream file.
	tu=$base/$ru # Absoluate path of template *.upstream file.
	le=${lu%.upstream} # Path of local copy (without the .upstream).
	if test -e "$lu"
	then
		# Both local and template *.upstream files exist.
		if cmp -s -- "$lu" "$tu"
		then
			# But they are different! At least one of them must be
			# outdated.
			if
				test "`git_uxts "$base" "$ru"`" \
					-gt "`git_uxts /etc "$ru"`"
			then
				problem OUTDATED "$tu" cp -- "$lu" "$tu"
			else
				problem OUTDATED "$bau" cp -- "$tu" "$lu"
			fi
		elif test ! -e "$le"
		then
			# We have a local *.upstream file without a
			# corresponding local file without the ".upstream"
			# suffix.
			problem ORPHANED "$lu" rm -- "$lu"
		elif cmp -s -- "$le" "$lu"
		then
			# We have both a local *.upstream file and a
			# corresponding local file, but both are identical. It
			# does not seem we need the upstream file any longer,
			# because there are no local modifications.
			problem USELESS "$lu" rm -- "$lu"
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
			cmp -s -- "$le" "$tu" && continue # Unmodified.
			# The working file is different from the template
			# upstream version. We should keep a local upstream
			# copy around for documenting the differences!
			problem MISSING "$lu" cp -- "$tu" "$lu"
		else
			# There is neither a local working file nor a local
			# upstream copy. Obviously we do not need such a
			# working copy at all. Fine.
			continue
		fi
	fi
done
# Process all local /etc *.upstream files.
find -H /etc -name .git -prune -o ! -type d -name '*.upstream' -print \
| while IFS= read -r lu
do
	le=${lu%.upstream}
	if test -e "$le"
	then
		# Both a local upstream and local working file exist.
		if cmp -s -- "$lu" "$le"
		then
			# But they are identical!
			problem USELESS "$lu" rm -- "$lu"
		fi
	else
		# They are different. As was to be expected. Good.
		continue
	fi
done
