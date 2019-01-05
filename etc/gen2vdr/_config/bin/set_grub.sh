#!/bin/bash
#set -x
BOOT_DISK=$(grep "^boot = " /etc/lilo.conf |cut -f 3- -d " ")
grub-install --no-floppy --recheck $BOOT_DISK
BOOT_PART=$(grep " /boot " /proc/mounts | cut -f 1 -d " ")
BPD=${BOOT_PART:0:8}
BPN=$((${BOOT_PART:(-1)} - 1))
GRUB_DEV=$(grep $BPD /boot/grub/device.map | cut -f 2 -d "(" | cut -f 1 -d ")") #"
ROOT_PART=$(readlink /dev/root)
sed -i /boot/grub/grub.conf -e "s/(hd.,.)/($GRUB_DEV,$BPN)/" -e "s%root=/dev/.d.. %root=/dev/$ROOT_PART %"
