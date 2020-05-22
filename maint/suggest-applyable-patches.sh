# Find all files in $etc for which there are can patches still be applied
# from $tpl and emit a patch for applying those changes to the current
# user's version of the files.
#
# When feeding the output of the script back into it and specifying the -S
# option, it will apply those patches where the check-mark has not been
# removed. It will create *.upstream copies of the patched files unless such
# copies already exist. The script will first check whether all patches can be
# applied before actually modifying any files.
#
# -R is like -S, except that no patches will be applies, but rather the
# un-checked patches will be written to a subdirectory which must exist but be
# empty, and which is the option argument to -R.
#
# When called with option -F, an existing and empty subdirectory must be
# specified as an argument, will will be filled with patches that are
# available but which could not be applied and need manual help.
#
# Version 2020.143

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
rejected=false
selectively_apply=false
while getopts SR:F: opt
do
	case $opt in
		S) selectively_apply=true;;
		F) failed=$OPTARG;;
		R) failed=$OPTARG; rejected=true;;
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

# chdir to $etc and make $tpl relative to it.
cd -- "$etc"
tpl=${tpl#"$etc"}; tpl=${tpl##/}
test -d "$tpl/maint"

TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

upatch() {
	test -e "$TD"/$2.rej && rm "$TD"/$2.rej
	patch -sfi "$TD"/$1 -- "$TD"/$2 > "$TD"/$3 2>& 1 || return
	test ! -e "$TD"/$2.rej || return
}

mkfailname() {
	o=`printf '%s\n' "$1" | sed 's|[/]|--|g; y/ /_/'`
	o=$failed/$o.patch
	test ! -e "$o"
}

if $selectively_apply || $rejected
then
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
					echo "Unrecognized '$line'!" >& 2
					false || exit
			esac
			read lines more rest
			expr x"$lines" : x'[1-9][0-9]*$' > /dev/null
			test "$more" = "$follow2"
			# Avoid including the separating "---"...-line within
			# the patch because it would confuse "recountdiff".
			lines=`expr $lines - 1`
			head -n $lines > "$TD"/p
			IFS= read -r rest
			expr x"$rest" : x'-\{5,\}$' > /dev/null
			if $no
			then
				m=${line#"$nopat"}
				if $rejected
				then
					mkfailname "$m"
					echo "Saving unapplied patch for $m"
					cat < "$TD"/p > "$o"
				fi
				continue
			fi
			$rejected && continue
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
		$rejected && break
	done
	exit
fi

udiff() {
	TZ=UTC0 diff -u -- "$1" "$2" > "$TD"/$3 2> "$TD"/$4 || :
}

find -H "$tpl" -name '*.upstream' -type f \
| while IFS= read -r tu
do
	tm=${tu%.upstream}
	test ! -e "$tm" && continue
	u=${tu#"$tpl/"}
	m=${tm#"$tpl/"}
	test ! -e "$m" && continue
	if test -e "$u"
	then
		cat < "$u" > "$TD"/o
	else
		cat < "$m" > "$TD"/o
	fi
	udiff "$tu" "$tm" p e
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
