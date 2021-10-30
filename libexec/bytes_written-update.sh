#! /bin/sh
# Append the total bytes written to a block device since boot to a statistics
# file.
#
# Normally, this script shall by symlinked from some directory like
# /var/lib/lifetime-writes where the state file shall also be stored.
#
# Then just run the symlink as a script.
#
# Alternatively, the directory where the state file should be stored may be
# specified as the only argument of the script. It is also possible to specify
# an arbitrary file in this directory, such as the state file itself, but then
# only the directory containing the file will actually be used and the
# specified file does not matter.
#
# No matter how the directory for the state file has been determined, the
# state file will then be written to (or be appended in) that directory using
# the file name "${writes_pfx}${devuuid}${writes_sfx}" (after calculating the
# values of the variables used in this string expression).
#
# Version 2021.2
# Copyright (c) 2019-2021 Guenther Brunthaler. All rights reserved.
#
# This script is free software.
# Distribution is permitted under the terms of the GPLv3.

writes_pfx=bytes_written-saved-
writes_sfx=.txt

set -e
trap 'test "$?" = 0 || echo "\"$0\" failed!" >& 2' 0

create=false
dry_run=false
show_stats=false
binary=false
exactly=false
while getopts cnsbX opt
do
	case $opt in
		c) create=true;;
		n) dry_run=true;;
		s) show_stats=true;;
		b) binary=true; show_stats=true;;
		X) exactly=true; show_stats=true;;
		*) false || exit
	esac
done
shift `expr $OPTIND - 1 || :`

# Determine statistics output directory $d.
case $# in
	1) d=$1; test -e "$d";; # File or directory.
	0)
		d=$0 # No argument, use script as argument.
		case $d in
			/*) ;;
			*)
				d=`pwd`/${d##/} # Make relative path absolute.
				test -f "$d"
		esac
		;;
	*) false || exit
esac
if test ! -d "$d"
then
	d=`dirname -- "$d"` # Get directory where the file lives in.
fi
d=`readlink -f -- "$d"`
test -d "$d"

# Get major, minor device numbers of device on which $d is located.
mi=`command stat -c '%d' -- "$d"`; test "$mi"
ma=`expr "$mi" / 256 || :`; mi=`expr "$mi" % 256 || :`

# Look up the device with that device numbers.
dev_with_dnum() {
	POSIXLY_CORRECT=on LC_ALL=POSIX command ls -dog1 /dev/* \
	| sed '
		s|^b[^,]*[^0-9]\([0-9]\{1,\}\), *\([0-9]\{1,\}\)[^/]*|\1 \2 |
		t; d
	' | {
		while read -r dma dmi dev
		do
			if test "$dma $dmi" = "$1 $2"
			then
				echo "$dev"
				exit
			fi
		done
		echo "No device $1:$2 found!" >& 2
		false || exit
	}
}

# Get UUID of device (rather than partition).
while :
do
	dev=`dev_with_dnum $ma $mi`; test "$dev"; test -b "$dev"
	devuuid=`
		blkid -s PARTUUID -o value -- "$dev" \
		| sed 's/-[0-9]*$//; s/[^[:xdigit:]]//g' | tr A-F a-f
	`
	test "$devuuid" && break
	command -v dmsetup > /dev/null
	mapping=`
		dmsetup ls | sed '
			s|^\([^[:space:]]\{1,\}\)[[:space:]]*('$ma:$mi')$|\1|
			t; d
		'
	`
	test "$mapping"
	mami=`
		dmsetup table "$mapping" | sed '
			s|.* \([0-9]\{1,3\}\):\([0-9]\{1,3\}\) .*|\1 \2|
			t; d
		' | head -n 1
	`
	test "$mami"
	ma=${mami%% *}; mi=${mami#"$ma "}
	test "$ma"; test "$mi"
done

check_writable() {
	test -w "$2" && return
	$dry_run && return
	echo "$1 '$2' is not writable!" >& 2
	echo "Maybe you have to 'mount -o remount,rw $3'?" >& 2
	false || exit
}

writes=${d%%/}/$writes_pfx$devuuid$writes_sfx
if test ! -f "$writes"
then
	if $create
	then
		echo "Creating '$writes'..." >& 2
		check_writable Directory "$d" "$dev"
		if $dry_run
		then
			:
		else
			> "$writes"
		fi
	else
		echo "Save-file '$writes' does not exist!"
		echo "Run again with option -c in order to create it."
		false || exit
	fi >& 2
fi

if $show_stats
then
	# Statistics accumulation mode.
	last_boot=; last_written=0; sum=0
	accumulate() {
		sum=`expr $sum + $last_written || :`
	}
	while read boot written
	do
		test "$boot"; test "$written"
		case $boot in
			"$last_boot") ;;
			*) accumulate; last_boot=$boot
		esac
		last_written=$written
	done < "$writes"
	accumulate
	if $binary
	then
		mult=1024
	else
		mult=1000
	fi
	if $exactly || expr $sum '<' 10 \* $mult > /dev/null
	then
		echo "$sum bytes"
		exit
	fi
	for u in K M G T P E Z Y
	do
		fract=`expr $sum \* 10 / $mult % 10 || :`
		sum=`expr $sum / $mult || :`
		if expr $sum '<' $mult > /dev/null || test $u = Y
		then
			break
		fi
	done
	if $binary
	then
		u=${u}iB
	else
		case $u in
			k) u=k
		esac
		u=${u}B
	fi
	eval `
		locale -k LC_NUMERIC 2> /dev/null | grep ^decimal_point= \
		|| echo decimal_point=.
	`
	echo "$sum$decimal_point$fract $u"
	exit
fi

# Update mode.
check_writable Save-file "$writes" "$dev"

# Get base device $p.
p=`expr x"$dev" : x'\(.*[^1-9]\)[1-9][0-9]*$'`
case $p in
	*p) p0=${p%p}; test -b "$p0" && p=$p0
esac
p=`basename -- "$p"`

# Extract statistics.
s=/sys/block/$p/stat
test -f "$s"
u=`cat /proc/sys/kernel/random/boot_id`
test "$u"
w=`awk '{print $7}' "$s"`
test "$w"
w=`expr $w \* 512 || :`

# Update statistics save file.
$dry_run && writes=/dev/null
echo "$u $w" | tee -a "$writes"
