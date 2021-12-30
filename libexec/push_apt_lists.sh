#! /bin/sh
s=~gb/prj/sysadmin/apt-fake/sync-2-xquad
c=cbfa03ce2b189244d7d63d622ced4c10b668db95a963d656021c46242630ce78
set -e
trap 'test $? = 0 || echo "\"$0\" failed" >& 2' 0
test -f "$s"
test "`sha256sum -b < "$s" | cut -d ' ' -f 1`" = $c
"$s"
