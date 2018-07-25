# Find all upstream files present only in the template directory.
set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0
base=`readlink -f -- "$0"`
for up in 1 2 3
do
	base=`dirname -- "$base"`
done
cd -- "$base"
test -d tpl; test -d etc

find tpl -name "*.upstream" | while IFS= read -r u; do d=etc/${u#*/}; test -e "$d" && continue; echo "$d"; done
