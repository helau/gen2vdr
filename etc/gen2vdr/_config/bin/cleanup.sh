#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x

MOUNTS="$(mount |grep " /m"|grep -v "^/dev/"|cut -f 1 -d " "|tr "\n" " ")"
if [ "$MOUNTS" != "" ] ; then
   umount $MOUNTS &
   for i in 1 2 3 4 5 6 7 8 9 10; do
      [ "$(pidof umount)" = "" ] && break
   done
   [ "$(pidof umount)" != "" ] && killall -9 umount
   MOUNTS="$(mount |grep " /m"|grep -v "^/dev/"|cut -f 1 -d " "|tr "\n" " ")"
   [ "$MOUNTS" != "" ] && umount -f $MOUNTS &
fi

#if [ "$WAKEONLAN" = "1" ] ; then
#   if [ "$(lspci -n |grep " 0200: 10ec:8168 ")" != "" ] && [ "lsmod |grep r8169" != "" ] ; then
#      /etc/init.d/network stop
#      /etc/init.d/staticroute stop
#      /etc/init.d/dhcpcd stop
#      modprobe -r r8169
#      modprobe r8168
#  fi
#   cat /proc/acpi/wakeup |logger
#fi
/_config/bin/activy_lcdoff.sh > /dev/null 2>&1

rm -f $(find /log /root/.screen -follow -mtime +5 -type f | grep -v "g2v_log_install")
rm -f $(find /root/ -mtime +2 -type f -name "kodi_crash*")
rm -f $(find /var/run -type f -name *.pid)
[ -s /etc/adjtime ] &&  rm /etc/adjtime

#grep "unknown config parameter" /log/messages | sed -e "s%.*ERROR: unknown config parameter: %%" | sort -u | while read i; do 
#   sed -i /etc/vdr/setup.conf -e "/$i/d"
#done

if [ "$WAKEONLAN" = "1" ] ; then
   ifconfig |grep "^e" |cut -f 1 -d ":" | while read i ; do
      ethtool -s "${i}" wol g
   done
   # Return 0 always
   for i in PCI0 NMAC LAN0 ; do
      if [ "$(grep "${i}.*disabled" /proc/acpi/wakeup 2>/dev/null)" != "" ] ; then
         echo -n $i > /proc/acpi/wakeup
      fi
   done
   cat /proc/acpi/wakeup |logger
fi
