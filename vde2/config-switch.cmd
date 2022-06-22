# VDE Switch Information
# ======================
#
# Switch Host: xquad


# Management socket
# -----------------
#
# ----
# $ rlwrap unixterm /var/run/vde2/ethvm.mgmt
# ----


# Switch interface socket
# -----------------------
#
# /var/run/vde2/ethvm.ctl


# VLANs
# -----

# IMPORTANT: Don't change the comment at the end of the lines in the next
# section! They are used by external scripts in order to associate VLAN
# numbers with the label shown in the comment.

# Connected via (isolated) host interface "ethvm".
vlan/create 1 # vm

# Access the isolated host-local SAMBA server (containing confidential data).
vlan/create 2 # smb

# Bridged to the host's LAN card (for VMs providing PXE servers, DHCP etc).
vlan/create 3 # br


# Port assignments
# ----------------
#
# Syntax: port/setvlan <port> <vlan>
# Syntax: port/create <port>

# Network interface "ethvm" on host "xxxxx" (only between VMs)
#port/create 1
port/setvlan 1 1

# Network interface "ethsmb" on host "xxxxx" (SAMBA access)
port/create 2
port/setvlan 2 2

# Network interface "ethbvm" on host "xxxxx" (bridging to host LAN)
port/create 3
port/setvlan 3 3


# Clean up
# --------

# Get rid of now-unused original VLAN.
#
# Bug: The next line makes the vde_switch from version 2.3.2+r586-2.2 of
# package vde2 crash.
##vlan/remove 0


# Static port allocations
# -----------------------

# User gb: 'Windows XP'
port/create 4
port/setvlan 4 2

# User gb: 'Knoppix 8.6', 'GRML Linux 2014.03'
port/create 5
port/setvlan 5 1

port/create 6
port/setvlan 6 1

port/create 7
port/setvlan 7 1

port/create 8
port/setvlan 8 1
