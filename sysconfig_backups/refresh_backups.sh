#! /bin/sh
# Create files documenting the current system configuration, especially
# partition layout and hardware configuration.
#
# The generated files as well as the configuration file for this script are
# intended to be kept under version control. This allows to detect changes to
# those configuration details later on.
#
# Version 2021.312
# (c) 2011-2021 by Guenther Brunthaler.
# This script is free software.
# Distribution is permitted under the terms of the GPLv3.


# LVM2 config file location (optional if LVM is not in use).
LVM2_CONF=/etc/lvm/lvm.conf


die() {
	echo "ERROR: $*" >& 2
	false; exit
}


run() {
	"$@" && return
	die "Command >>>$*<<< failed with return code ${?}!"
}


getcmd() {
	case $1 in
		-*) ;;
		*) set -- -- "$@"
	esac
	# There is a bug in bash's eval: It does not return the status of a
	# backquote substitution. Adding a redundant test to fix it.
	eval "$2=`which \"$3\" 2> /dev/null`;\
		test \$? = 0 && test -n \"\$$2\" && test -x \"\$$2\"" \
			&& return
	eval "$2="
	test $1 = "-f" && die "Required utility '$3' is not installed!"
	! test $1 != "-i"
}


print_lvm2_backup_dir() {
	expand "$LVM2_CONF" \
	| sed -e '
		s/^ *//
		s/^#.*//
		/^$/ d
	' | "$AWK" '
		BEGIN {i= 0}
		$2 == "{" {ns[i++]= $1}
		$1 == "}" {--i}
		/=/ {
			split($0, t, " *= *")
			if ( \
				i == 1 && ns[0] == "backup" \
				&& t[1] == "backup_dir" \
			) {
				v= t[2]
				if (match(v, "\"") > 0) {
					v= substr(v, RSTART + RLENGTH)
					if (match(v, "\" *$") > 0) {
						v= substr(v, 1, RSTART - 1)
					}
				}
				print v
			}
		}
	'
}


LC_ALL=C
export LC_ALL
getcmd -f AWK awk
getcmd -f MKTEMP mktemp
t=`"$MKTEMP" -- "${TMPDIR:-/tmp}"/${0##*/}.XXXXXXXXX`
trap "rm -- '$t'" 0
if getcmd FDISK fdisk && getcmd SFDISK sfdisk
then
	for DEV in /sys/block/*
	do
		DEV=${DEV##*/}
		case $DEV in
			loop[0-9]* | dm-* | ram[0-9]* | sr[0-9]* \
			| nbd[0-9]*) continue
		esac
		test -e /dev/"$DEV" || continue
		run test -b /dev/"$DEV"
		"$SFDISK" -d /dev/"$DEV" 2> /dev/null > "$t" || continue
		echo "Examining /dev/$DEV..." >& 2
		cat "$t" > sfdisk_"$DEV"_backup.txt
		"$FDISK" -lu /dev/"$DEV" 2> /dev/null > "$t" || continue
		"$AWK" '
			/[^ ]/ {print}
			/dentifier:/ {exit}
		' < "$t" > disk-id_"$DEV"_info.txt
	done
else
	echo "fdisk or sfdisk is missing," \
		"skipping partition table backups." >& 2
fi
if getcmd LSHW lshw
then
	"$LSHW" > lshw.txt
else
	echo "lshw is not installed; skipping." >& 2
fi
if ! getcmd BZR bzr || test ! -d /etc/.bzr
then
	BZR=
fi
if
	test -f "$LVM2_CONF" \
	&& { getcmd LVM lvm2 || getcmd LVM lvm; } \
	&& LVM2_BACKUP_DIR=`print_lvm2_backup_dir` \
	&& test -n "$LVM2_BACKUP_DIR" && test -d "$LVM2_BACKUP_DIR"
then
	"$LVM" vgdisplay | grep "VG Name" | "$AWK" '{print $NF}' |
	while read vg
	do
		if test -n "$BZR"
		then
			s=`
				"$BZR" st --short -- "$LVM2_BACKUP_DIR"/"$vg"
			` || s=X
			case $s in
				X* | "?"*) ;; # Unknown or ignored.
				*) continue # Version controlled; skip it.
			esac
		fi
		"$LVM" vgcfgbackup -f "$vg.lvm" "$vg"
	done
fi
if getcmd LSMOD lsmod
then
	run "$LSMOD" | run tail -n +2 | run cut -d" " -f1 \
	| LC_ALL=C run sort > loaded_modules.txt
fi
if getcmd UNAME uname
then
	run "$UNAME" -a > "current_kernel.txt"
fi
if getcmd CPUID cpuid
then
	run "$CPUID" > cpu_features.txt
fi
