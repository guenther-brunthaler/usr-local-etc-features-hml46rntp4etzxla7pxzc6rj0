#! /bin/false
# This file is sourced by init.d scripts via the lsb helper scripts.
# We use it to maintain a trace log what the scripts are actually doing.
#
# v2026.141

# Define default values.

# Create this empty directory in order for the scripts to mount a tmpfs
# there and creating a log file within it.
rclogmpt=/run/rclog
rclogfile=log
rclogmax=100m # Suffixes: k, m, g, ...

# Source defaults file (if any), allowing the user to override above settings.
test -f /etc/default/rclog && . /etc/default/rclog

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
