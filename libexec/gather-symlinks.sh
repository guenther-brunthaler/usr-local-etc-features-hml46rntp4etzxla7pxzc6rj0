#! /bin/sh
set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0

find . ! -path . | LC_COLLATE=C sort \
| while IFS= read -r fso
do
	fso=${fso#./}
	if test -L "$fso"
	then
		t=`readlink -- "$fso"`
		printf '%s\n' "$fso"
		echo "--> $t"
	elif test -d "$fso"
	then
		:
	elif test -f "$fso"
	then
		:
	else
		echo "wtf is '$fso'?!" >& 2
		false || exit
	fi
done
