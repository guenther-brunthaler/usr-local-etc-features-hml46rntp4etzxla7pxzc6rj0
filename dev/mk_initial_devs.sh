#! /bin/sh

# This script does not need to be actually stored in /dev, but it can be run
# from there (once) in order to create the initial/basic static device nodes
# for a Linux system (as of Debian 12).
#
# v2023.176.2

while read args
do
	mknod -m $args
done << EOF
666 null c 1 3
666 zero c 1 5
666 full c 1 7
666 random c 1 8
666 urandom c 1 9
666 tty c 5 0
600 console c 5 1
666 ptmx c 5 2
EOF
mkdir pts shm
ln -s /proc/self/fd fd
ln -s fd/0 stdin
ln -s fd/1 stdout
ln -s fd/2 stderr
