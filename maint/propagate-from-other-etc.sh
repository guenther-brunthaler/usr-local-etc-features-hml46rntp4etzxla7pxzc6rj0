# Invoke this script with a single argument: The pathname of a check-out of
# an older /etc, containing only versioned files.
#
# Then this script will try to transplant the differences from $FILE to
# $FILE.upstream found in that directory to the files in the current "etc".
#
# All successful tranplants will remove the $FILE and $FILE.upstream from
# the older checkout.
#
# Version 2026.16

set -e
cleanup() {
	rc=$?
	test "$TD" && rm -r -- "$TD"
	test $rc = 0 || echo "\"$0\" failed!" >& 2
}
TD=
trap cleanup 0
trap 'exit $?' HUP QUIT INT TERM PIPE

dry_run=false
while getopts n opt
do
	case $opt in
		n) dry_run=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

die() {
	printf '%s\n' "$*" >& 2
	false || exit
}

if test $# != 1 || test ! -d "$1"
then
	die "Exactly one argument:" \
		"Path to old /etc checkout as patch transplant source"
fi
case $1 in
	/*) src=$1;;
	*) src=$PWD/$1
esac
while expr x"$src" : x'/.*/$' > /dev/null
do
	src=${src%/}
done

# Set $etc and $tpl based on $0.
tpl=$0
while :
do
	etc=`dirname -- "$tpl"`
	test "$etc" = . && etc=$PWD
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

test -d .git # We need $etc to be a git checkout.
TD=`mktemp -d -- "${TMPDIR:-/tmp}/${0##*/}".XXXXXXXXXX`

# Apply differences between $1 and $2 to $3. Use $4 and $5 as temporary files.
# If the differences have already been applied, act as if the application of
# the differences had been successful.
#
# If unsuccessful, try differences between comment-stripped $1 and $2 instead.
#
# $1 and $2 will never be modified. $3 will be updated only if successful.
#
# Returns the success status.
try_patch() {
	diff -u -- "$1" "$2" > "$4" || :
	cat -- "$3" > "$5"
	if patch -i "$4" -Nu -- "$5" 2> /dev/null
	then
		cat -- "$5" > "$3"
		return
	fi
	grep -e '^[[:space:]]*$' -e '^[[:space:]]*#' -- "$1" > "$5" || :
	diff -u -- "$5" "$2" > "$4" || :
	cat -- "$3" > "$5"
	if patch -i "$4" -Nu -- "$5" 2> /dev/null
	then
		cat -- "$5" > "$3"
		return
	fi
	false || return
}

run() {
	$dry_run && set echo "SIMULATION: $*"
	"$@"
}

find -H "$src" -xdev -path "$src"/.git -prune \
	-o -name '*.upstream' -type f -print \
| while IFS= read u
do
	u=${u#$src/}; b=${u%.upstream}
	test ! -e "$src/$b" && continue

	ok=true
	while :
	do	
		if test -e "$u"
		then
			# We have a matching *.upstream file in $etc. Try to
			# patch against that.
			cat -- "$u" > "$TD"/file
			if
				try_patch "$src/$u" "$src/$b" "$TD"/file \
					"$TD"/t1 "$TD"/t2
			then
				if test -e "$b"
				then
					# We also have a patched file in $etc.
					if cmp -s "$b" "$TD"/file
					then
						# They are the same: We
						# already have this patch
						# applied locally.
						break
					fi
				else
					break
				fi
			fi
		fi
		if test -e "$b"
		then
			# There is no matching *.upstream file in $etc, but
			# the (possibly already patched) base file is there.
			cat -- "$b" > "$TD"/file
			if
				try_patch "$src/$u" "$src/$b" "$TD"/file \
					"$TD"/t1 "$TD"/t2
			then
				break
			fi
		fi
		# The patch could not be applied and has not already been
		# applied. Fail. Ignore and keep the files in $src. Do not
		# change the file in $etc either.
		ok=false
		break
	done
	if $ok
	then
		# $TD/file has the patch successfully applied.
		if test ! -e "$u"
		then
			cp -- "$b" "$u"
		fi
		run git add -- "$u"
		if test -e "$b" && cmp -s -- "$b" "$TD"/file
		then
			:
		else
			run cp -- "$TD"/file "$b"
		fi
		run git add -- "$b"
		# This patch has been "consumed".
		echo "Consumed patch for $b"
		# Remove the related files from $src, so that they will not be
		# found again during later runs of the script.
		run rm -- "$src/$b"
		run rm -- "$src/$u"
	fi
done
