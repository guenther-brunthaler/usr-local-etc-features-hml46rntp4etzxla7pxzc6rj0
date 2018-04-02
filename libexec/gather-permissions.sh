#! /bin/sh
exclusions_file=ignore-contents

set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0

all=false
while getopts ax: opt
do
	case $opt in
		x) exclusions_file=$OPTARG;;
		a) all=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

println() {
	printf '%s\n' "$*"
}

ckmode() {
	local attr
	attr=`stat -c '%a %U %G' -- "$fso"`
	if $all
	then
		:
	else
		test "$attr" = "$2 $4 $5" && return
		test "$attr" = "$3 $4 $5" && return
	fi
	println "$1 $attr $fso"
}

set --
if test "$exclusions_file"
then
	set -f
	pfx=
	while IFS= read -r container
	do
		set -- "$@" $pfx-path ./"$container" -prune
		pfx='-o '
	done < "$exclusions_file"
	if test $# != 0
	then
		set -- \( "$@" -o -path \* \)
	fi
	set +f
fi
find ! -path . "$@" \
| while IFS= read -r fso
do
	fso=${fso#./}
	if test -L "$fso"
	then
		:
	elif test -d "$fso"
	then
		ckmode D 755 755 root root
	elif test -f "$fso"
	then
		ckmode F 644 755 root root
	else
		echo "wtf is '$fso'?!" >& 2
		false || exit
	fi
done | LC_COLLATE=C sort
