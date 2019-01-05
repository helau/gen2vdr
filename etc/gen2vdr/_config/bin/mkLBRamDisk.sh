#!/bin/bash
source /_config/bin/g2v_funcs.sh

LB=$(grep "LiveBuffer " /etc/vdr/setup.conf | cut -f 3 -d " ")
if [ "$LB" = "1" ] ; then
   LB_SIZE=$(grep "LiveBufferSize " /etc/vdr/setup.conf | cut -f 3 -d " ")
   MEM_SIZE=$(($(grep "MemTotal" /proc/meminfo  | tr -s " " | cut -f 2 -d " ")/1024))
   RD_SIZE=$(($LB_SIZE + 1))
   echo "$MEM_SIZE MB RAM is availabe"
   if [ $(($MEM_SIZE - $RD_SIZE)) -ge 50 ] ; then
      echo "Creating a RAM disk of $RD_SIZE MB"
      dd if=/dev/zero of=/dev/ram0 bs=1024k count=$RD_SIZE
      if [ "$?" = "0" ] ; then
         echo "Formatting and mounting RamDisk"
         mke2fs -vm0 -N 32 /dev/ram0
         if [ -f $VIDEO/LiveBuffer ] ; then
            rm -rf $VIDEO/LiveBuffer
         fi          
         mkdir $VIDEO/LiveBuffer
         mount -t ext2 -o noatime /dev/ram0 $VIDEO/LiveBuffer
      else
         echo "Error during creating a RAM disk of $RD_SIZE MB"
         freeramdisk /dev/ram0
      fi
   else
      echo "Cannot create a RAM disk of $RD_SIZE MB"
   fi
fi
