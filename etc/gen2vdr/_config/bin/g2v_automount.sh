#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x

execCmd() {
   glogger -s "Exec <$1>"
   $1 2>&1 |logger -s
}

if [ "$(pidof -x "$0" -o $$ -o $PPID -o %PPID)" != "" ] ; then
   glogger -s "$0 is already running"
   exit 1
fi

CD_DRIVES=""
# find CD drives
for i in /sys/block/??? ; do
   DEV=${i##*/}
   if [ "$(udevadm info --query=all --name=/dev/$DEV 2>/dev/null | grep " ID_TYPE=cd")" != "" ] ; then
      CD_DRIVES="${CD_DRIVES}$DEV "
      # Create Links if not already there
      for i in cdrom cdrw dvd dvdrw ; do
         if [ ! -e /dev/$i ] ; then
            execCmd "ln -s $DEV /dev/$i"
         fi
      done
   fi
done
if [ "$CD_DRIVES" != "" ] ; then
   [ ! -e /media/dvd ] && mkdir /media/dvd
fi

CD_INS=" "
OLD_DEV=" "
settled = 1
while [ 1 ] ; do
   NEW_DEV=" "
   for i in $(ls /sys/block/*/*/partition /sys/block/*/partition 2>/dev/null) ; do
      DEV=${i%/partition}
      DEV=${DEV##*/}
      NEW_DEV="${NEW_DEV}${DEV} "
      if [ "${OLD_DEV/* $DEV */}" != "" ] ; then
         glogger -s "New Partition <$DEV>"
         if [ "$(grep "/dev/${DEV:0:3}" /etc/fstab)" != "" -o "$(grep "^/dev/$DEV" /proc/mounts)" != "" ] ; then
            continue
         fi
         if [ $settled == 0 ] ; then
            udevadm settle
            settled = 0
         fi
         IS_FS=0
         FS_TYPE=""
         FS_LABEL=""
         while read line ; do
            case $line in
               *ID_FS_USAGE=filesystem)
                  IS_FS=1 ;;
               *ID_FS_TYPE=*)
                  FS_TYPE=${line##*=} ;;
               *ID_FS_LABEL=*)
                  FS_LABEL=${line##*=} ;;
            esac
         done < <(udevadm info --query=all --name=/dev/$DEV)
         if [ "$IS_FS" = "1" ] ; then
            glogger -s "<$IS_FS><$FS_TYPE><$FS_LABEL>"
            if [ "$FS_LABEL" = "" ] ; then
               LABEL="${DEV}"
            elif [ "$MOUNTNAMEDEV" = "1" ] ; then
               LABEL="${FS_LABEL}_${DEV}"
            else
               LABEL="${FS_LABEL}"
            fi
            if [ "$(cat /sys/block/${DEV:0:3}/removable)" = "1" ] ; then
               execCmd "pmount /dev/$DEV $LABEL"
            fi
            if [ "$(mount | grep "/dev/$DEV ")" == "" ] ; then
               mkdir /media/$LABEL 2>/dev/null
               execCmd "mount -t $FS_TYPE /dev/$DEV /media/$LABEL"
            fi
            MP=$(grep "^/dev/$DEV" /proc/mounts|cut -f 2 -d " ")
            if [ -d "$MP" ] ; then
               if [ -d "$MP/video" ] ; then
                  /_config/bin/linkvid.sh "$MP/video"
               fi
            fi
         fi
      fi
   done
   for i in $OLD_DEV ; do
      if [ "${NEW_DEV/* $i */}" != "" ] ; then
         glogger -s "Partition removed <$i>"
         execCmd "pumount /dev/$i"
         /_config/bin/linkvid.sh -check
      fi
   done
   OLD_DEV="$NEW_DEV"
   # check CD Drives
   if [ "$CD_DRIVES" != "" ] ; then
      NCD_INS=" "
      for i in $CD_DRIVES ; do
         CDSTAT=$(blkid /dev/$i)
         if [ "$CDSTAT" != "" ] ; then
            NCD_INS="${NCD_INS}${i} "
            if [ "${CD_INS/* $i */}" != "" ] ; then
#               if [ $CDSTAT -ge 4 ] ; then
                  execCmd "pmount /dev/$i"
#               fi
               execCmd "/_config/bin/disc_speed.sh -c /dev/$i"
               MP=$(grep "^/dev/$i" /proc/mounts|cut -f 2 -d " ")
               if [ -d "$MP" ] ; then
                  if [ -d "$MP/video" ] ; then
                     /_config/bin/linkvid.sh "$MP/video"
                  else
                     /_config/bin/linkvid.sh "$MP"
                  fi
               fi
            fi
         else
            if [ "${CD_INS/* $i */}" = "" ] ; then
               execCmd "pumount /dev/$i"
            fi
         fi
      done
      CD_INS="$NCD_INS"
   fi
   sleep 5
done
