#! /bin/false

# Install this snippet if you want UTF-8 support but do not want to install
# the "localepurge" package because of its dependencies "libc-l10n" and
# "locales". For a headless installation, those dependency packages typically
# allocate more space than "localepurge" might save.
#
# v2026.265
export LANG=C.UTF-8
