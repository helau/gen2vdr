#!/bin/bash
#set -x
if [ "$1" = "-c" ] ; then
   A_PLG=$(grep "^/" /etc/vdr/plugins/admin/admin.conf | grep -c ":PLG_")
   A_ALL=$(grep -c "^/" /etc/vdr/plugins/admin/admin.conf)
   V_ALL=$(grep -c "=\"" /etc/vdr.d/conf/vdr)
   APIVERSION="$(grep "define APIVERSION " /usr/local/src/VDR/config.h | cut -f 2 -d "\"")"
   NUM_PLG=$(ls /usr/local/lib/vdr/libvdr-*.so.$APIVERSION |wc -w)
   [ $(($A_ALL - $A_PLG + 1)) -eq $V_ALL ] && [ $A_PLG -eq $NUM_PLG ] && exit
fi
DT=$(date +"%Y%m%d%H%M")
cp -vf /etc/vdr/plugins/admin/admin.conf /etc/vdr/plugins/admin/admin.conf.updadm
cp -vf /etc/vdr/plugins/admin/admin.conf.default /etc/vdr/plugins/admin/admin.conf
sh /etc/vdr/plugins/admin/setadmconf.sh
cp -vf /etc/vdr.d/conf/vdr /etc/vdr.d/conf/vdr.conf.updadm
sh /etc/vdr/plugins/admin/setvdrconf.sh
