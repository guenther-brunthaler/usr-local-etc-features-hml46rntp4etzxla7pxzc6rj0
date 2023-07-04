# Version 2023.185
fignore=site-6n580p79r0flmgyv0feaxchll/local_only.list
patches=site-6n580p79r0flmgyv0feaxchll/template_patches
dignore=site-6n580p79r0flmgyv0feaxchll/ignore_dirs.list

set -e
cleanup() {
	rc=$?
	test "$TD" && rm -rf -- "$TD"
	test $rc = 0 || echo "$0 failed!" >& 2
}
TD=
trap cleanup 0
trap 'exit $?' HUP QUIT INT TERM

force=false
while getopts f opt
do
	case $opt in
		f) force=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

test $# = 1
outscript=$1
if test -e "$outscript"
then
	$force
fi

println() {
	printf '%s\n' "$*"
}

die() {
	println "$*" >& 2
	false || exit
}

# Set $etc and $tpl based on $0.
tpl=$0
while :
do
	etc=`dirname -- "$tpl"`
	test "$etc" != "$tpl"
	tpl=$etc
	test -d "$tpl"/maint && break
done
etc=`dirname -- "$tpl"`
test "$etc" != "$tpl"

# chdir to $etc and make $tpl relative to it.
cd -- "$etc"
tpl=${tpl#"$etc"}; tpl=${tpl##/}
test -d "$tpl/maint"

set find . \( -path ./.git
while IFS= read -r d
do
	test -d "./$d"
	set "$@" -o -path "./$d"
done <<- EOF
	$tpl
	site-6n580p79r0flmgyv0feaxchll
	upstream-versions-dbkkywcqxlt7w1u854dz5hhbk.d
EOF

if test -e "$dignore"
then
	while IFS= read -r d
	do
		test -d "./$d"
		set "$@" -o -path "./$d"
	done < "$dignore"
fi
set "$@" \) -prune -o -type f -print

TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

# Create a standard unified diff of $1 and $2 as "$TD/diff".
# Will not display any messages unless in case of failures.
# Returns true if $1 and $2 are equal.
udiff() {
	local rc
	LC_ALL=C TZ=UTC0 diff -u -- "$1" "$2" > "$TD"/diff \
		2> "$TD"/errors && rc=$? || rc=$?
	if test $rc -ge 2
	then
		{
			echo "ERROR: diff -u '$1' '$2'"
			cat < "$TD"/errors
		} >& 2
		false || exit
	fi
	return $rc
}

qin() {
	out=
	for arg
	do
		expr x"$arg" : x'[-_%/=,.[:alnum:]]*$' \
			> /dev/null \
		|| arg="'`println "$arg" | sed "s/'/&\\&&/g"`'"
		out=$out${out:+ }$arg
	done
	println "$out"
}

any=false
for f in "$fignore" "$dignore"
do
	LC_COLLATE=C sort -u < "$f" > "$TD"/local
	cmp -s -- "$f" "$TD"/local && continue
	echo "Re-sorting $f" >& 2
	cat < "$TD"/local > "$f"
	any=true
done
#test $any = false && exit

"$@" | cut -d / -f 2- \
| LC_COLLATE=C sort | LC_COLLATE=C comm -23 - "$fignore" \
| {
	sed 's/^|//' <<- 'EOF' >& 5
		#! /bin/sh
		xfer() {
		|	case $1 in
		|		">") cat < "$2" > "$3";;
		|		"<") cat > "$2" < "$3";;
		|		*) echo "ignore: '$1' for '$2' and '$3'" >& 2
		|	esac
		}

	EOF
	while IFS= read -r f
	do
		t=$tpl/$f
		test ! -e "$t" && continue
		if udiff "$t" "$f"
		then
			continue
		fi
		cat < "$TD"/diff
		qin xfer '>' "$t" "$f" >& 5
	done
} 5> "$outscript"
