#! /bin/false
# This file is sourced by init.d scripts via the lsb helper scripts.
# We use it to maintain a trace log what the scripts are actually doing.
#
# v2021.342

# Define default values.

# Create this empty directory in order for the scripts to mount a tmpfs
# there and creating a log file within it.
rclogmpt=/rclog
rclogfile=log
rclogmax=3g

# Source defaults file (if any), allowing the user to override above settings.
test -f /etc/defaults/rclog && . /etc/defaults/rclog

test ! -d "$rclogmpt" && return # Do nothing if mount point dir does not exist.
test -e "$rclogmpt"/no && return # Create tag file "no" there to stop logging.
if test ! -e "$rclogmpt/$rclogfile"
then
	mount -t tmpfs -o size=$rclogmax "$rclogfile" "$rclogmpt"
fi
exec >> "$rclogmpt/$rclogfile" 2>& 1
unset rclogmpt rclogfile rclogmax
echo ------------
date
set -xv
