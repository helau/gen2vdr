#!/bin/bash
source /_config/bin/g2v_funcs.sh

glogger -s "ADMIN - AUTOMOUNT: $AUTOMOUNT"

if [ "$AUTOMOUNT" = "1" ] ; then
   [ "$(rc-status default |grep automount)" = "" ] && rc-update add automount default
   /etc/init.d/automount start > /dev/null 2>&1
else
   [ "$(rc-status default |grep automount)" != "" ] && rc-update del automount
   /etc/init.d/automount stop > /dev/null 2>&1
fi
echo 'Done!'
exit 0
