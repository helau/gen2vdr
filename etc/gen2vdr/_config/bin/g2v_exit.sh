#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh

if [ -f /autostop.next ] ; then
   mv -f /autostop.next /autostop.vdr
fi

# check for noad
/_config/bin/check_noad.sh -exit

SESSIONS=$(ps x | grep "[0-9] -bash" | grep -v tty | cut -b 1-5)
[ "$SESSIONS" != "" ] && kill -9 $SESSIONS > /dev/null 2>&1

NET_FS="nfs cifs smbfs"

# save dmesg entries
DT=$(date +%m%d%H%M)
[ -f /log/dmsg ] && rm -f /log/dmsg
mkdir -p /log/dmsg 2>/dev/null
dmesg > /log/dmsg/dmesg.${DT}

# umount some devices
mount | tac | while read i; do
  if [ "${i#/dev/loop}" != "$i" ]; then
     logger -s "Unmounting <$i>"
     umount ${i%% *}
  else
     for j in $NET_FS; do
        if [ "${i/* type $j */}" = "" ]; then
           logger -s "Unmounting <$i>"
           umount ${i%% *}
        fi
     done
  fi
done
