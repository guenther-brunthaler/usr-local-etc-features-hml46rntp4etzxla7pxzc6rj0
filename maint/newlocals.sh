# Version 2020.54
#
# Display a list of all local configuration files which may
# be suitable to be copied over to the template directory.
#
# This only lists new such files, not updated/modified existing ones.

fignore=site-6n580p79r0flmgyv0feaxchll/local_only.list
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

if test ! -e "$ignore"
then
	ignore=/dev/null
fi

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

"$@" | cut -d / -f 2- \
| {
	rx35='[0-9a-np-z]\{25\}'
	sep='[^[:alnum:]]'
	sed '
		/^'"$rx35"'$/ b uuid
		/'"$sep$rx35"'$/ b uuid
		/'"$sep$rx35$sep"'/ b uuid
		b
		:uuid
		h; s/.*//; p; g
	'
} \
| {
	uuid_next=false
	while IFS= read -r f
	do
		case $f in
			'') uuid_next=true; continue
		esac
		uuid=$uuid_next; uuid_next=false
		test -e "$tpl/$f" && continue
		case $f in
			*.upstream) ;;
			*)
				case $uuid in
					true) ;;
					*) continue
				esac
				
		esac
		printf '%s\n' "$f"
	done
} \
| LC_COLLATE=C sort | LC_COLLATE=C comm -23 - "$fignore"
