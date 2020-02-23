# Version 2020.54
#
# Refresh a cache of local and template upstream diffs. For files present
# locally and in the template but whithout upstream diffs, diffs between
# the template and local versions will be kept instead.
#
# All diffs are stored relative to /etc in a cache directory with the
# following suffixes added to their original names:
#
# .ll.diff - local changes against local upstream
# .tt.diff - template changes against template upstream
# .lt.diff - local changes against template
#
# In addition to those files, checksum files of normalized versions of those
# files exist with filename extension ".ck" instead of ".diff".
#
# The cache directory in /etc must be a symlink to an actual directory
# outside of /etc, such as below /var/tmp or /var/cache.

cachedir=site-6n580p79r0flmgyv0feaxchll/diffs-cache
dignore=site-6n580p79r0flmgyv0feaxchll/ignore_dirs.list

set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0

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

test -L "$cachedir"
test -d "$cachedir"

# Is file $1 newer than $2? Both files must exist.
newer() {
	local f
	case $1 in
		-*) f=./$1;;
		*) f=$1
	esac
	test `find -H "$f" -newer "$2" | wc -l` = 1 || false
}

# Update cache file $3 (and its associated checksum file) with diff of $1
# against $2, but omit this if $3 already exists and is newer than both $1 and
# $2. $1 and $2 must already exist.
may_update() {
	test -e "$3" && newer "$3" "$1" && newer "$3" "$2" && return
	echo "Updating $3" >& 2
	TZ=UTC0 LC_ALL=C diff -u -- "$1" "$2" > "$3" || :
	sed '
		1,2 d # Ignore initial "---" and "+++" lines.
		s/^\([^-+]\).*/\1/
	' "$3" \
	| openssl sha256 | cut -d " " -f 2 > "${3%.*}.ck"
}

"$@" | cut -d / -f 2- \
| while IFS= read -r f
do
	case $f in
		*.upstream) test -f "${f%.*}"; continue
	esac
	c=$cachedir/$f
	u=$f.upstream
	t=$tpl/$f
	tu=$t.upstream
	test ! -e "$u" && test ! -e "$t" && test ! -e "$tu" && continue
	mkdir -p -- "`dirname -- "$c"`"
	if test -e "$u"
	then
		may_update "$f" "$u" "$c".ll.diff
	elif test -e "tu"
	then
		may_update "$t" "$tu" "$c".tt.diff
	else
		may_update "$f" "$t" "$c".lt.diff
	fi
done
