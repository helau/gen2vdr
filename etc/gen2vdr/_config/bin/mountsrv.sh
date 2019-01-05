#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh

PATH=$PATH:/usr/local/bin

SERVER=$1

if [ "$SERVER" = "" ] ; then
   echo "Server mit angeben! Usage: $0 IP or PC-Name [stop]"
   exit 1
fi
#set -x
if [ "$(pidof portmap)" = "" ] ; then
   /etc/init.d/portmap start
   rc-update add portmap default
fi

for j in `seq 1 3` ; do
   if [ "$(mount | grep /mnt/video-${SERVER})" != "" ] ; then
      umount -f /mnt/video-${SERVER}
   fi
done

if [ -d $VIDEO/_VIDEO-${SERVER} ] ; then
   rm $VIDEO/_VIDEO-${SERVER}/* > /dev/null 2>&1
else
   mkdir $VIDEO/_VIDEO-${SERVER}
fi

if [ "$2" = "stop" ] ; then
    touch $VIDEO/.update
    exit 0
fi

srvdown=0
for i in `seq 1 10` ; do
   ping -c 1 -w 2 $SERVER > /dev/null 2>&1
   srvdown=$?
   if [ "$srvdown" = "0" ] || [ "$1" = "test" ] ; then
      break;
   fi
   sleep 3
done
#set -x
if [ "$srvdown" = "0" ] ; then
   [ ! -d /mnt/video-${SERVER} ] && mkdir /mnt/video-${SERVER}
   mount -o rw,soft,bg ${SERVER}:/video /mnt/video-${SERVER}

   cd /mnt/video-${SERVER}

   for i in * ; do
     if [ "$(find /mnt/video-${SERVER}/${i}/ -name "index*")" != "" ] ; then
        ln -s /mnt/video-${SERVER}/${i} $VIDEO/_VIDEO-${SERVER}/
     fi
   done
   touch $VIDEO/.update
   svdrps "MESG Server <${SERVER}> erfolgreich verbunden" > /dev/null 2>&1
else
   svdrps "MESG Server <${SERVER}> kann nicht erreicht werden" > /dev/null 2>&1
fi
