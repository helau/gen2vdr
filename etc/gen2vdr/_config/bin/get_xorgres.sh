#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh
X_CFG=/etc/X11/xorg.conf

RES=""

case $SCREEN_RESOLUTION in 
   720p)
      RES="1280x720";;
   1080i)
      RES="1920x1080";;
   1080p)
      RES="1920x1080";;
   VGA2SCART)
      RES="720x576";;
   *)
      ALL_RES="$(grep -m 1 "640x480 800x600 1024x768" $X_CFG | cut -f 2 -d "\"")"
      if [ "${ALL_RES/*$SCREEN_RESOLUTION*/}" = "" ] ; then
         RES=${SCREEN_RESOLUTION}
      fi
      ;;
esac
[ "$RES" != "" ] && echo "$RES"
