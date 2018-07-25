# Copy all missing template files to the etc directory.
set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0
base=`readlink -f -- "$0"`
for up in 1 2 3
do
	base=`dirname -- "$base"`
done
cd -- "$base"
test -d tpl; test -d etc

find tpl -path tpl/.git -prune -o -type f -print | while IFS= read -r s
do
	d=etc/${s#*/}; test -e "$d" && continue
	mkdir -p -- "`dirname -- "$d"`"
	set -x
	cp -ai -- "$s" "$d"
	set +x
done
