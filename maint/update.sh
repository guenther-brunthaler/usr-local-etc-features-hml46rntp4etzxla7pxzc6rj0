# Replace all files which exist on both sides with the template version.

set -e
cleanup() {
	rc=$?
	test "$TD" && rm -r -- "$TD"
	test $rc = 0 || echo "$0 failed!" >& 2
}
TD=
trap cleanup 0
trap 'exit $?' INT TERM QUIT HUP

base=`readlink -f -- "$0"`
for up in 1 2 3
do
	base=`dirname -- "$base"`
done
cd -- "$base"
test -d tpl; test -d etc

ask=false
while getopts a opt
do
	case $opt in
		a) ask=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

exec 5<& 0
find tpl -path tpl/.git -prune -o -type f -print | while IFS= read -r s
do
	d=etc/${s#*/};
	test -f "$s" && test -f "$d" || continue
	cmp -s -- "$s" "$d" && continue
	if test "${s%.upstream}" != "$s"
	then
		if
			test -f "${s%.upstream}" && test -f "${s%.upstream}"
		then
			continue
		fi
		diff -u -- "$s" "${s%.upstream}" > "$TD"/sdiffs
		diff -u -- "$d" "${d%.upstream}" > "$TD"/ddiffs
		diff -u -- "$TD"/ddiffs "$TD"/sdiffs || :
	else
		diff -u -- "$d" "$s" || :
	fi
	if $ask
	then
		cp -ai -- "$s" "$d" <& 5
	fi
done
