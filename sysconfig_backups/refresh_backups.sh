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
if FDISK=`which fdisk 2> /dev/null` && SFDISK=`which sfdisk 2> /dev/null`
then
	for DEV in /sys/block/*
	do
		DEV=${DEV##*/}
		case $DEV in
			loop[0-9]* | dm-* ) continue
		esac
		test -e /dev/"$DEV" || continue
		echo "Examining /dev/$DEV..." >& 2
		run test -b /dev/"$DEV"
		run "$FDISK" -lu /dev/"$DEV" | awk '
			/[^ ]/ {print}
			/dentifier:/ {exit}
		' > disk-id_"$DEV"_info.txt
		run "$SFDISK" -d /dev/"$DEV" > sfdisk_"$DEV"_backup.txt
	done
else
	echo "fdisk or sfdisk is missing," \
		"skipping partition table backups." >& 2
fi
if LSHW=`which lshw 2> /dev/null`
then
	"$LSHW" > lshw.txt
else
	echo "lshw is not installed; skipping." >& 2
fi
if ! BZR=`which bzr 2> /dev/null` || test ! -d /etc/.bzr
then
	BZR=
fi
if LVM=`which lvm 2> /dev/null`
then
	"$LVM" vgdisplay | grep "VG Name" | awk '{print $NF}' |
	while read vg
	do
		if test -n "$BZR"
		then
			s=`"$BZR" st --short -- /etc/lvm/backup/"$vg"` || s=X
			case $s in
				X* | "?"*) ;; # Unknown or ignored.
				*) continue # Version controlled; skip it.
			esac
		fi
		"$LVM" vgcfgbackup -f "$vg.lvm" "$vg"
	done
fi
