# Find all upstream files present only in the template directory.
#
# Version 2020.51
set -e
trap 'test $? = 0 || echo "\"$0\" failed!" >& 2' 0
base=`readlink -f -- "$0"`
base=`dirname -- "$base"`
base=`dirname -- "$base"`
cd -- "$base"
find . -name "*.upstream" \
| while IFS= read -r u
do
	u=${u#./}
	d=${u#"$base"}
	test -e /etc/"$d" && continue
	echo "$d"
done
