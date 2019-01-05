#!/bin/bash
#
source /etc/vdr.d/conf/vdr
source /etc/vdr.d/conf/gen2vdr.cfg

LCD_SCRIPTS="LCDd"

OLD_LCDS=",$(grep ":LCD:" /etc/vdr/plugins/admin/admin.conf|cut -f 6 -d ":"),"
NEW_LCDS=""
CHANGED=0
for i in $(ls /usr/lib/lcdproc/ |sed -e "s/\.so/ /g"|sort -f) ; do
   NEW_LCDS="${NEW_LCDS}${i},"
   if [ "${OLD_LCDS/*,$i,*/}" != "" ] ; then
      CHANGED=1
   fi
done
if [ "$CHANGED" = "1" ] ; then
   sed -i /etc/vdr/plugins/admin/admin.conf -e "s/\(.*\):LCD:\(.*\):L:.*:\(.*\):\$/\1:LCD:\2:L:0:${NEW_LCDS}None:\3:/"
   if [ "${NEW_LCDS/*$LCD,*/}" != "" ] ; then
      LCD="None"
   fi
   $SETVAL LCD "$LCD"
fi

[ "$1" = "-check" ] && exit

if [ "$LCD" = "None" ]; then
   rc-update del LCDd boot > /dev/null 2>&1
   /etc/init.d/LCDd stop > /dev/null 2>&1
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<haslcd>true</haslcd>%<haslcd>false</haslcd>%"
else
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<haslcd>false</haslcd>%<haslcd>true</haslcd>%"
   if [ "${LCD/*imon*/}" = "" ] ; then
      if [ "${LCD/*imonlcd*/}" = "" ] ; then
         /_config/bin/module-update.sh args imon "display_type=2"
      else
         /_config/bin/module-update.sh args imon "display_type=1"
      fi
      modprobe imon
      /_config/bin/module-update.sh add imon >/dev/null
   fi
   if [ "${LCD/*imonlcd*/}" = "" -o "${LCD/*dm140*/}" = "" -o "${LCD/*activy3*/}" = "" ] ; then
      rc-update del LCDd boot > /dev/null 2>&1
   else
      rc-update add LCDd boot > /dev/null 2>&1
   fi
   sed -i /etc/LCDd.conf -e "s/^Driver=.*G2V.*/Driver=${LCD}       # G2V do not change/"
   /etc/init.d/LCDd start > /dev/null 2>&1
fi
echo 'Done!'
