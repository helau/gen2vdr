#!/bin/bash
source /etc/vdr.d/conf/vdr
if [ "$BOOT_SPLASH" == "1" ] ; then
   DB="G2V-Splash"
else
   DB="Gen2VDR"
fi
sed -i /etc/lilo.conf -e "s%^default =.*%default = $DB%"
lilo
