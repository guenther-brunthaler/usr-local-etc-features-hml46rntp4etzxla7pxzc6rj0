#! /bin/sh
# Create files documenting the current system configuration, especially
# partition layout and hardware configuration.
#
# The generated files as well as the configuration file for this script are
# intended to be kept under version control. This allows to detect changes to
# those configuration details later on.
#
# (c) 2011 - 2013 by Guenther Brunthaler.
# This script is free software.
# Distribution is permitted under the terms of the GPLv3.


die() {
	echo "ERROR: $*" >& 2
	false; exit
}


run() {
	"$@" && return
	die "Command >>>$*<<< failed with return code ${?}!"
}


LC_ALL=C
export LC_ALL
for DEV in /sys/block/*
do
	DEV=${DEV##*/}
	case $DEV in
		loop[0-9]* | dm-* ) continue
	esac
	test -e /dev/"$DEV" || continue
	echo "Examining /dev/$DEV..." >& 2
	run test -b /dev/"$DEV"
	run fdisk -lu /dev/"$DEV" | awk '
		/[^ ]/ {print}
		/dentifier:/ {exit}
	' > disk-id_"$DEV"_info.txt
	run sfdisk -d /dev/"$DEV" > sfdisk_"$DEV"_backup.txt
done
if LSHW=`which lshw 2> /dev/null`
then
	"$LSHW" > lshw.txt
else
	echo "lshw is not installed; skipping." >& 2
fi
if which lvm /dev/null 2>& 1
then
	vgdisplay | grep "VG Name" | awk '{print $NF}' |
	while read vg
	do
		vgcfgbackup -f "$vg.lvm" "$vg"
	done
fi
