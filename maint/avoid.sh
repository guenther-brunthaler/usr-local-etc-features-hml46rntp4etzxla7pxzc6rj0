# Remove all unwanted files which may have been copied over from the template.
UNWANTED=tpl-merge/unwanted.lst

set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0
base=`readlink -f -- "$0"`
for up in 1 2 3
do
	base=`dirname -- "$base"`
done
cd -- "$base"
test -d tpl; test -d etc

cd etc
test -f "$UNWANTED"
while IFS= read -r u <& 5
do
	test ! -e "$u" && continue
	rm -ri -- "$u"
done 5< "$UNWANTED"
