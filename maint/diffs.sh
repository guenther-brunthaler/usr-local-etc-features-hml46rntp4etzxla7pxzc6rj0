# Version 2023.137
#
# Report differences between which exist in the local /etc as well as in the
# shared template for /etc.
#
# Local directories in $dignore (if this file exists) will not be examined.
#
# Neither will be any of the files in $fignore be examined.
#
# Before comparison with a template file, any existing patch from $patches
# will be applied to (a copy of) the local file.

# The following paths are relative to the directory from which THIS script has
# been invoked as "./$tpl/maint/$scriptname" where $tpl is the arbitrary name
# of some subdirectory or symlink and "$scriptname is the basename of THIS
# script.
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

die() {
	printf '%s\n' "$*" >& 2
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

# Create a standard unified diff of $1 and $2 as "$TD/diff" and a
# postprocessed more comparison-tolerant version of the diff as "$TD/cmp".
# Will not display any messages unless in case of failures.
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
	return
	sed '
		1,2 d # Ignore initial "---" and "+++" lines.
		s/^\([^-+]\).*/\1/
	' "$TD"/diff > "$TD"/cmp
}

# Patch "$TD"/local with patch file $1, reporting $2 as the file name
# in case of errors.
upatch() {
	rm -f -- "$TD"/local.rej
	patch -i "$1" -- "$TD"/local > "$TD"/errors 2>& 1 \
	|| {
		{
			echo "ERROR: Problem applying patches for $2"
			cat < "$TD"/errors
			if test -e  "$TD"/local.rej
			then
				echo; echo "REJECTED patch:"
				cat < "$TD"/local.rej
			fi
		} >& 2
		false || exit
	}
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
$any && echo

"$@" | cut -d / -f 2- \
| LC_COLLATE=C sort | LC_COLLATE=C comm -23 - "$fignore" \
| while IFS= read -r f
do
	case $f in
		*.upstream)
			u=$f; f=${u%.upstream}
			p=$patches/$f; pp=$p.prepatch; p=$p.patch
			test -f "$f" || die "Orphaned $u"
			test ! -f "$tpl/$u" && continue
			test -f "$tpl/$f" || die "Missing $tpl/$f"
			# Create template patch.
			udiff "$tpl/$u" "$tpl/$f"
			cat < "$f.upstream" > "$TD"/local
			if test -e "$pp"
			then
				upatch "$pp" "$f" # Apply pre-patch.
			fi
			upatch "$TD"/diff "$f" # Apply template patch.
			cat < "$TD"/local > "$TD"/template
			if test -e "$p"
			then
				upatch "$p" "$f" # Apply local patch.
			fi
			if cmp -s -- "$TD"/local "$f"
			then
				:
			else
				udiff "$TD"/template "$f"
				echo "Refreshing $p" >& 2
				mkdir -p -- "`dirname -- "$p"`"
				cat < "$TD"/diff > "$p"
			fi
			;;
		*)
			test -e "$f.upstream" && continue
			test ! -e "$tpl/$f" && continue
			test ! -e "$tpl/$f.upstream" \
				|| die "Missing $f.upstream"
			cat < "$tpl/$f" > "$TD"/local
			p=$patches/$f; pp=$p.prepatch; p=$p.patch
			if test -e "$pp"
			then
				upatch "$pp" "$f" # Apply pre-patch.
			fi
			if test -e "$p"
			then
				upatch "$p" "$f" # Apply local patch.
			fi
			if cmp -s -- "$TD"/local "$f"
			then
				:
			else
				udiff "$TD"/local "$f"
				echo "Refreshing $p" >& 2
				mkdir -p -- "`dirname -- "$p"`"
				cat < "$TD"/diff > "$p"
			fi
	esac
done
