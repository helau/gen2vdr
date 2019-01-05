#!/bin/bash
source /_config/bin/g2v_funcs.sh

sed -i /etc/lilo.conf -e "s% irqpoll%%"

# check for Reycom
if [ "$(lsusb |grep -i "0bc7:000c")" != "" ] && [ "$(biosinfo | grep "IPX7A-330")" != "" ] ; then
   cp /etc/asound.conf.reycom /etc/asound.conf
   sed -i /etc/lilo.conf -e "s%\(^append.*HOME=/root\)\"$%\1 irqpoll\"%"
fi

#check for nvidia boards
if [ "$(lsmod |grep -i "forcedeth")" != "" ] ; then
   sed -i /etc/lilo.conf -e "s%HOME=/root.*%HOME=/root pci=nomsi\"%"
   echo "module_ngene_args=\"shutdown_workaround=1\"" >> /etc/conf.d/modules
   echo "options ngene shutdown_workaround=1" >> /etc/modprobe.d/g2v.conf
fi
