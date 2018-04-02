#! /bin/sh
save_file=/etc/special-permissions
base_dir=/etc

set -e
trap 'test $? = 0 || echo "$0 failed!" >& 2' 0

while getopts d:p: opt
do
	case $opt in
		d) base_dir=$OPTARG;;
		p) save_file=$OPTARG;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

cd -- "$base_dir"
while IFS=' ' read -r type mode user group path
do
	test "${path#/}" = "$path"
	if test -L "$path"
	then
		false || exit
	elif test -d "$path"
	then
		test "$type" = D
	elif test -f "$path"
	then
		test "$type" = F
	elif test ! -e "$path"
	then
		case $type in
			D) mkdir -p -- "$path";;
			F)
				mkdir -p -- "`dirname -- "$path"`"
				> "$path"
				;;
			*) false || exit
		esac
	else
		echo "wtf is '$path'?!" >& 2
		false || exit
	fi
	test "`stat -c '%a %U %G' -- "$path"`" = "$mode $user $group" \
		&& continue
	chown $user:$group -- "$path"
	chmod $mode -- "$path"
	echo "Restored `ls -dl -- "$path"`"
done < "$save_file"
