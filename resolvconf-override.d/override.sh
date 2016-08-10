#! /bin/sh
# Hook $ADDITIONAL_LIBEXECDIR into the list of directories searched for
# resolvconf subscribers.

ADDITIONAL_LIBEXECDIR=/etc/resolvconf-subscribers.d

LIBEXECDIR=$ORIGINAL_LIBEXECDIR
unset ORIGINAL_LIBEXECDIR

# The following is mostly a copy of the logic in resolvconf, just using an
# additional directory $ADDITIONAL_LIBEXECDIR for locating the subscribers.
retval=0
for script in "$LIBEXECDIR"/* "$ADDITIONAL_LIBEXECDIR"/*
do
	if test -f "$script"
	then
		if test -x "$script"
		then
			"$script" "$cmd" "$iface"
		else
			(set -- "$cmd" "$iface"; . "$script")
		fi
		retval=`expr $retval + $? || :`
	fi
done
exit $retval
