#! /bin/false
# Version 2018.225
# Copyright (c) 2018 Guenther Brunthaler. All rights reserved.
#
# This shell startup script is free software.
# Distribution is permitted under the terms of the GPLv3.
#
# This will be sourced by login shells only.

# According to POSIX, normal shells only have to source $ENV.
ENV=~/.shellrc

s_e4qual15jp5vqx7p5aksw93z0=~/.profile.d
if test -d "$s_e4qual15jp5vqx7p5aksw93z0"
then
	for s_e4qual15jp5vqx7p5aksw93z0 in "$s_e4qual15jp5vqx7p5aksw93z0"/*
	do
		{
			test -f "$s_e4qual15jp5vqx7p5aksw93z0" \
			&& expr x"${s_e4qual15jp5vqx7p5aksw93z0##*/}" \
				: x'[_[:alnum:]]\{3,\}$' > /dev/null
		} || continue
		. "$s_e4qual15jp5vqx7p5aksw93z0"
	done
fi
unset s_e4qual15jp5vqx7p5aksw93z0

# Enhancement: Source $ENV also for login shells.
if test -f "$ENV"
then
	export ENV
	. "$ENV"
else
	unset ENV
fi
