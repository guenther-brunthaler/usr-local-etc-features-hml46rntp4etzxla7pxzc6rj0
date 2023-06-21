#! /bin/sh
# v2023.137
default_topdirs='/srv/tftp /srv/tftp/ramfs'

set -e
cleanup() {
	rc=$?
	test "$TF" && rm -- "$TF"
	test $rc = 0 || echo "\"$0\" failed!" >& 2
}
TF=
trap cleanup 0
trap 'exit $?' INT QUIT TERM HUP

while getopts '' opt
do
	case $opt in
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

TF=`mktemp -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

append_info() {
	e="$e  [$1]"
}

sizeconv() {
	s=`expr $s \* 1024`
	for u in kB MB GB TB PB EB ZB YB
	do
		c=`expr $s + 50`
		case ${#c} in
			4 | 5 | 6)
				c=${c%??}; s=${c%?}; c=${c#"$s"}
				append_info "$s.$c $u"
				return
				;;
			*) s=${s%???}
		esac
	done
	false || exit
}

case $# in
	0) set -- $default_topdirs
esac
i=$#
while :
do
	case $i in
		0) break
	esac
	test -d "$1"
	case $1 in
		-*) set -- "$@" ./"$1";;
		*) set -- "$@" "$1"
	esac
	shift
	i=`expr $i - 1 || :`
done

f=dir
find -H "$@" -xdev -type d \
| while IFS= read -r d
do
	cd -- "$d"
	while :
	do
		first=true
		ls -ksF1 | while IFS=' ' read -r s e
		do
			if $first
			then
				first=false
				continue
			fi
			case $e in
				*"@")
					s=${e%"@"}
					if test -L "$s"
					then
						append_info "'`readlink \
							-- "$s"`'"
					fi
					;;
				*/ | *"|") ;;
				*)
					f=${e%"*"}
					test -f "$f" || s=''
					case $s in
						'') ;;
						0) append_info "0 bytes";;
						*) sizeconv
					esac
			esac
			printf '%s\n' "$e"
		done > "$TF"
		if test -e $f && cmp -s -- "$TF" $f
		then
			:
		else
			echo "Updating $d/$f..."
			cat < "$TF" > $f
		fi
		test -s "$TF" && break
	done
done
