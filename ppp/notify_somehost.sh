#! /bin/sh
INFO=/var/lib/misc/last_reported_ip4
REPORT_URL="http://555.555.555.555/report"
REPORT_URL2=
WGETOPT="--no-proxy --timeout=10"

set -e
test $# = 1
IP=$1
test -n "$IP"
HOST=`hostname`
REPORT_URL=$REPORT_URL/$HOST
test -n "$HOST"
(
	flock -n 9
	KIP=
	read KIP < "$INFO" || :
	test x"$KIP" = x"$IP" && exit
	if
		! wget $WGETOPT -O /dev/null \
		"$REPORT_URL/$IP" \
		> /dev/null 2>& 1 \
		&& test -n "$REPORT_URL2"
	then
		wget $WGETOPT -O /dev/null \
			"$REPORT_URL2/$IP" \
			> /dev/null 2>& 1 \
		|| :
	fi
	echo "$IP" > "$INFO"
) 9>> "$INFO"
