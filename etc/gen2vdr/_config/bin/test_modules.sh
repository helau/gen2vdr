#!/bin/bash
#
# Pfade zu den benötigten Dateien
PCIMAP=/lib/modules/`uname -r`/modules.pcimap
USBMAP=/lib/modules/`uname -r`/modules.usbmap

if [ "$1" != "" ] ; then
for i in $(cat $1) ; do
   Vendor=$(cat $i/vendor | cut -f 2 -d "x")
   Device=$(cat $i/device | cut -f 2 -d "x")
   SV=$(cat $i/subsystem_vendor | cut -f 2 -d "x")
   SD=$(cat $i/subsystem_device | cut -f 2 -d "x")
#   echo $i   
#   echo "0x0000$Vendor 0x0000$Device 0x0000$SV 0x0000$SD"
   driver=$(grep "0x0000$Vendor 0x0000$Device 0x0000$SV 0x0000$SD" $PCIMAP)
   if [ "$driver" = "" ] ; then
      driver=$(grep "0x0000$Vendor 0x0000$Device 0xffffffff 0xffffffff" $PCIMAP | cut -f 1 -d " ")
   fi
   if [ "$driver" = "" ] ; then
      echo "No driver found for <$i>" >&2
   else
      echo "$driver"
   fi   
done   
fi

[ "$2" = "" ] && exit
Newline=$'\n'
IFS="${Newline}"
cat $USBMAP | tr -s " " | cut -f 1-4 -d " " > /tmp/~USB
#set -x
for i in $(cat $2 | sed -e "s/.* ID //") ; do
   Vendor=$(echo $i | cut -b 1-4)
   Device=$(echo $i | cut -b 6-9)
   Info=$(echo $i | cut -f 2- -d " ")
   if [ "$Vendor" = "0000" ] ; then
      continue
   fi
#   echo "0x$Vendor 0x$Device <$Info>"
   driver=$(grep -i "0x$Vendor 0x$Device" /tmp/~USB | cut -f 1 -d " ")
#   if [ "$driver" = "" ] ; then
#      driver=$(grep "0x$Vendor 0x0000$Device 0xffffffff 0xffffffff" $PCIMAP | cut -f 1 -d " ")
#   fi
   if [ "$driver" = "" ] ; then
      echo "No driver found for USB 0x$Vendor 0x$Device <$Info>" >&2
   else
      echo "$driver"
   fi
done   
