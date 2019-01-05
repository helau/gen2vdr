#! /bin/bash
source /_config/bin/g2v_funcs.sh
#
#set -x
MOUNT_POINT="/media"

usb_mount() {
   if [ ! -e $MOUNT_POINT ] ; then
      mkdir -p $MOUNT_POINT
   fi
   if [ "$1" = "" -o "$1" = "-check" ] ; then
      ALL_DEV="$(mount |grep "^/dev" | cut -b 6-8 |sort -u | tr "\n" " ")"
      cd /sys/block
      USB_DEV=""

      for i in $(grep -H [1] /sys/block/???/removable | cut -f 4 -d "/") ; do
#         [ "${i:0:2}" = "hd" ] && continue
         [ "$(cat /sys/block/$i/size)" = "0" ] && continue
         grep -v "^0$" /sys/block/*/size
         case $ALL_DEV in
            *$i*)
                echo "Already mounted <$i>"
                ;;
            *)
                FOUND=0
                for j in $(ls -d /sys/block/$i/$i[0-9] 2>/dev/null); do
                   echo "Found <${j}>"
                   USB_DEV="$USB_DEV /dev/${j##*/}"
                   FOUND=1
                done
                [ "$FOUND" = "0" ] && USB_DEV="$USB_DEV /dev/$i"
                ;;
         esac
      done
   else
      USB_DEV=$1
   fi
   USB_MOUNTS=$(mount | grep "^/dev" | grep "on ${MOUNT_POINT}/usb" | cut -f 3 -d " ")
   glogger -s "USB: <${USB_DEV}-${USB_MOUNTS}>"
   for i in $USB_DEV ; do
      i=${i%/}
      MOUNTED="$(mount | grep "^${i}" | cut -f 3 -d " ")"
      if [ "$MOUNTED" = "" ] ; then
         MP="${MOUNT_POINT}/usb_$(echo $i | cut -f 3 -d "/")"
         [ ! -e ${MP} ] && mkdir ${MP}
         mount $i ${MP}
         MOUNTED="$(mount | grep "^${i}" | cut -f 3 -d " ")"
         if [ "$MOUNTED" = "" ] ; then
            glogger -s "Error mounting $i - retrying with force"
            mount $i ${MP} -o force
            MOUNTED="$(mount | grep "^${i}" | cut -f 3 -d " ")"
         fi
         if [ "$MOUNTED" != "" ] ; then
            glogger -s "$i mounted on ${MP}"
            svdrps MESG "$i mounted on ${MP}"
            screen -dm sh -c "sh /_config/bin/linkvid.sh ${MP}"
         else
            glogger -s "Error $? <mount $i ${MP}>"
         fi
      else
         glogger -s "$i is already mounted"
         screen -dm sh -c "sh /_config/bin/linkvid.sh ${MOUNTED}"
      fi
   done
}

usb_unmount() {
   if [ "$1" = "" -o "$1" = "-check" ] ; then
      USB_MOUNTS=$(mount | grep "^/dev" | grep "on ${MOUNT_POINT}/usb" | cut -f 1 -d " ")
   else
      USB_MOUNTS=$(mount | grep "^$1" | grep "on ${MOUNT_POINT}/usb" | cut -f 1 -d " ")
   fi
#   echo "<$USB_MOUNTS>"
   for i in $USB_MOUNTS ; do
      [ "$1" = "-check" ] && [ -e $i ] && continue
      umount ${i} > /dev/null 2>&1
      glogger -s "${i} unmounted"
      svdrps MESG "$i unmounted"
      rmdir ${i} > /dev/null 2>&1
      /_config/bin/linkvid.sh ${i} -del
   done
   rmdir $MOUNT_POINT/usb* > /dev/null 2>&1
}

#set -x
glogger "$0 -$1-$2-$3"
if [ "$1" = "-mount" ] ; then
   [ "$2" = "" ] && usb_unmount
   usb_mount $2
elif [ "$1" = "-unmount" ] || [ "$1" = "-umount" ] ; then
   usb_unmount $2
elif [ "$1" = "-remount" ] ; then
   usb_unmount
   echo "$0 -mount"
   screen -dm sh -c "sleep 5 | $0 -mount"
else
   glogger -s "usbmount unknown parameter <$1>"
   echo "Syntax: $0 [-mount|-umount|-remount] [device]"
fi
