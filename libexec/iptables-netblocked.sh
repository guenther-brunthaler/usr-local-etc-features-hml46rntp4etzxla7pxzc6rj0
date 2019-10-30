#! /bin/false

# Block internet access for users in group "netblocked".

(
	log() {
		local CATEGORY TOPIC
		CATEGORY=$1; shift
		TOPIC="`pwd`/$SCRIPT"
		logger -p daemon.$CATEGORY -t "$TOPIC" "$*"
	}


	die() {
		log err "$*"
		false; exit
	}


	run() {
		"$@" && return
		die "Could not execute >>>$*<<<, return code ${?}"
	}


	ipt() {
		run iptables "$@"
	}
	

	LOSER=netblocked
	STILL_ALLOWED=127.0.0.0/8

	set -f; oldIFS=$IFS
	IFS=','; set -- `grep ^netblocked:x: /etc/group | cut -d : -f 4`
	IFS=$oldIFS; set +f

	# Erase all rules from the filter table.
	log info "Setting firewall rules"
	ipt -F
	ipt -X
	ipt -N LOGGER
	ipt -A LOGGER -j LOG --log-uid --log-prefix "[FW] blocked " \
		--log-level warning
	ipt -A LOGGER -j REJECT
	ipt -N NETLESS
	ipt -A NETLESS -m limit --limit 3/minute -j LOGGER
	ipt -A NETLESS -j REJECT
	ipt -A OUTPUT -d "$STILL_ALLOWED" -j ACCEPT
	for user
	do
		ipt -A OUTPUT -m owner --uid-owner "$user" -j NETLESS
	done
) || exit
