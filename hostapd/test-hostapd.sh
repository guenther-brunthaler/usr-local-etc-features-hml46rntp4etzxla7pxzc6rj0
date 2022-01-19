#! /bin/sh
# Useful just for debugging. Do not use in production environment.
#
# v2022.19

exec /usr/sbin/hostapd -P /run/hostapd.pid -dd /etc/hostapd/hostapd.conf
