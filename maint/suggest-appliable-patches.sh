#! /bin/sh
exit_version() {
	wr -s << === && exit
$APP version 2020.144.2

Copyright (c) 2020 Guenther Brunthaler. All rights reserved.

This script is free software.
Distribution is permitted under the terms of the GPLv3.
===
}
APP=${0##*/}

exit_help() {
	wr << === && echo && exit_version
$APP - suggest cumulative patch to be applied to `pwd`

Usage: $APP [ <options> ... ]

$APP finds all files in `pwd` for which there are can patches still be applied
from `pwd`/$tpl/* and emit a patch for applying those changes to the current
user's version of the files.

-S: When feeding the edited output of an earlier invocation of $APP back into
it and specifying this option, it will apply those patches where the
check-mark have not been removed. It will also create *.upstream copies of the
patched files unless such copies already exist. The script will first check
whether all patches can be applied successfully before actually modifying any
files.

-R is like -S, except that no patches will be applied. Instead, all un-checked
individual patches (i. e. those that have been rejected by the user by editing
the cumulative patch and manually removing the check-mark) will be extracted
from the cumulative patch and will be written to a subdirectory which is
specified as the option argument to -R. This directory must already exist and
be empty.

-F: An existing and empty subdirectory must be specified as an option
argument, which will be filled with failed patches that are available but
which could not be applied and need manual help.

-L: Emit a list of executable commands which will create a copy of all
(relative) symbolic links which exist in `pwd`/$tpl/* but not in `pwd` yet.
Already existing filesystem objects with the same names will not be
overwritten. Instead, commented-out creation commands will be written for such
symlinks. The output can be feeded back into a shell (after possible manual
editing), typically with also passing the -xe options to the shell invocation.
===
}

set -e
cleanup() {
	rc=$?
	test "$TD" && rm -rf -- "$TD"
	test $rc = 0 || echo "$0 failed!" >& 2
}
TD=
trap cleanup 0
trap 'exit $?' HUP QUIT INT TERM

failed=
action=
while getopts LSR:F:hV opt
do
	case $opt in
		L) action=symlinks;;
		S) action=selectively_apply;;
		F) failed=$OPTARG;;
		R) failed=$OPTARG; action=rejected;;
		h) action=help;;
		V) action=version;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

test $# = 0

case $failed in
	'') ;;
	*)
		case $failed in
			-*) failed=./$failed
		esac
		test -d "$failed"
		test "`find -H "$failed" | wc -l`" = 1
esac

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

# chdir to $etc and make $tpl relative to it as an appropriate starting
# pathname argument to "find" (i. e. not starting with '-").
cd -- "$etc"
tpl=${tpl#"$etc"}; tpl=${tpl##/}
case $tpl in
	-*) tpl=./$tpl
esac
test -d "$tpl/maint"

wr() {
	case $# in
		0)
			{
				sep=
				while IFS= read -r line
				do
					printf %s%s "$sep" "$line"
					if test "$line"
					then
						sep=' '
					else
						echo
						test -z "$sep" && continue
						echo; sep=
					fi
				done
				test -z "$sep" || echo
			} | wr -s
			;;
		*) fold -sw $LINEWIDTH | sed 's/[[:space:]]*$//'
	esac
}
LINEWIDTH=`
	cmd=tput; command -v $cmd > /dev/null 2>& 1 \
	&& test -t 0 && $cmd cols \
	|| echo ${COLUMNS:-66}
`

case $action in
	help) exit_help;;
	version) exit_version;;
esac

TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

upatch() {
	test -e "$TD"/$2.rej && rm "$TD"/$2.rej
	patch -sfi "$TD"/$1 -- "$TD"/$2 > "$TD"/$3 2>& 1 || return
	test ! -e "$TD"/$2.rej || return
}

println() {
	printf '%s\n' "$*"
}

mkfailname() {
	o=`println "$1" | sed 's|[/]|--|g; y/ /_/'`
	o=$failed/$o.patch
	test ! -e "$o"
}

case $action in
	selectively_apply | rejected)
		yespat='[x] patch '
		nopat='[ ] patch '
		follow2='lines'
		cat > "$TD"/instructions
		for phase in prepare apply
		do
			while IFS= read -r line
			do
				case $line in
					"$yespat"*) no=false;;
					"$nopat"*) no=true;;
					*)
						echo "Unrecognized" \
							"'$line'!" >& 2
						false || exit
				esac
				read lines more rest
				expr x"$lines" : x'[1-9][0-9]*$' > /dev/null
				test "$more" = "$follow2"
				# Avoid including the separating "---"...-line
				# within the patch because it would confuse
				# "recountdiff".
				lines=`expr $lines - 1`
				head -n $lines > "$TD"/p
				IFS= read -r rest
				expr x"$rest" : x'-\{5,\}$' > /dev/null
				if $no
				then
					m=${line#"$nopat"}
					case $action in
						rejected)
							mkfailname "$m"
							echo "Saving" \
								"unapplied" \
								"patch" \
								"for $m"
							cat < "$TD"/p > "$o"
							;;
					esac
					continue
				fi
				case $action in
					rejected) continue
				esac
				m=${line#"$yespat"}
				test -f "$m"
				cat < "$m" > "$TD"/m
				upatch p m e
				case $phase in
					prepare)
						u=$m.upstream
						test -f "$u" && continue
						test ! -e "$u"
						cp -p -- "$m" "$u"
						git add -- "$u"
						;;
					apply)
						cat < "$TD"/m > "$m"
						git add -- "$m"
						;;
					*) false || exit
				esac
			done < "$TD"/instructions
			case $action in
				rejected) break
			esac
		done
		exit
esac

udiff() {
	TZ=UTC0 diff -u -- "$1" "$2" > "$TD"/$3 2> "$TD"/$4 || :
}

qin() {
	out=
	for arg
	do
		expr x"$arg" : x'[-_%/=,.[:alnum:]]*$' > /dev/null \
		|| arg="'`println "$arg" | sed "s/'/&\\&&/g"`'"
		out=$out${out:+ }$arg
	done
	println "$out"
}

set find -H "$tpl" \( -path "$tpl"/maint -o -path "$tpl"/.git \) -prune
case $action in
	symlinks)
		nfirst=
		"$@" -o -type l -print \
		| while IFS= read -r tm
		do
			m=${tm#"$tpl/"}
			target=`readlink -- "$tm"`
			bad=
			if test -L "$m"
			then
				case $target in
					"`readlink -- "$m"`") continue ;;
					*) bad=y;;
				esac
			elif test -e "$m"
			then
				bad=y
			fi
			case $nfirst in
				'') nfirst=yes;;
				*) echo
			esac
			case $m in
				*/*)
					set -- "`dirname -- "$m"`"
					case $1 in
						-*) set -- -- "$@"
					esac
					echo "${bad:+"#"}`qin mkdir -p "$@"`"
			esac
			set -- "$target" "$m"
			case $1 in
				-*) set -- -- "$@"
			esac
			echo "${bad:+"#"}`qin ln -s${bad:+"nf"} "$@"`"
			set -- "$m"
			case $1 in
				-*) set -- -- "$@"
			esac
			echo "${bad:+"#"}`qin git add "$@"`"
		done
		exit
esac
"$@" -o -type f -print \
| while IFS= read -r tm
do
	m=${tm#"$tpl/"}
	tu=$tm.upstream
	u=${tu#"$tpl/"}
	test ! -e "$m" && continue
	if test -e "$u"
	then
		cat < "$u" > "$TD"/o
	else
		cat < "$m" > "$TD"/o
	fi
	if test -e "$tu"
	then
		udiff "$tu" "$tm" p e
	else
		udiff "$m" "$tm" p e
	fi
	cat < "$TD"/o > "$TD"/m
	if upatch p m e
	then
		test "$failed" && continue
		udiff "$m" "$TD"/m p e2
		test ! -s "$TD"/p && continue
		echo "[x] patch $m"
		{
			if test -s "$TD"/e
			then
				echo "Which applied with the following" \
					"warnings:"
				cat < "$TD"/e
			fi
			cat < "$TD"/p
			echo -------------------
		} > "$TD"/t
		echo "`wc -l < "$TD"/t` lines follow before next prompt or EOF"
		cat < "$TD"/t
	elif test "$failed"
	then
		mkfailname "$m"
		echo "Saving failed patch for $m"
		cat < "$TD"/p > "$o"
	fi
done
