#!/bin/bash
source /_config/bin/g2v_funcs.sh

X_CFG="/etc/X11/xorg.conf"

NEW_SCREEN=""
RES=""

case $SCREEN_RESOLUTION in 
   720p)
      RES="1280x720"
      NEW_SCREEN="S_720P";;
   1080i)
      RES="1920x1080"
      NEW_SCREEN="S_1080I";;
   1080p)
      RES="1920x1080"
      NEW_SCREEN="S_1080P";;
   2160p)
      RES="3840x2160"
      NEW_SCREEN="S_2160P";;
   VGA2SCART)
      RES="720x576"
      NEW_SCREEN="S_V2S";;
   manuell)
      glogger -s "Screen not changed (Manuell)";;
   *)
      RES=$SCREEN_RESOLUTION
      NEW_SCREEN="S_PC"
      sed -i $X_CFG -e "s/\(.*Modes.*\)\".*\".*\(#G2V.*\)/\1\"${SCREEN_RESOLUTION}\" \2/"
      ;;
esac

if [ "$VO_DRIVER" = "ffdvb" ] ; then
   sed -i /etc/vdr/setup.conf -e "s/OSDWidthP.*/OSDWidthP = 0.800000/" -e "s/OSDHeightP.*/OSDHeightP = 0.800000/" \
                              -e "s/OSDWidth .*/OSDWidth = 632/" -e "s/OSDHeight .*/OSDHeight = 507/" \
                              -e "s/OSDAspect .*/OSDAspect = 1.066667/" \
                              -e "s/OSDTopP.*/OSDTopP = 0.100000/" -e "s/OSDLeftP.*/OSDLeftP = 0.100000/"
elif [ "$RES" != "" ] ; then
   XP=$(grep "^OSDWidthP =" /etc/vdr/setup.conf | cut -f 2 -d "=")
   XP=${XP#*\.}
   XP=${XP:0:2}
   XP=${XP#0}
   YP=$(grep "^OSDHeightP =" /etc/vdr/setup.conf | cut -f 2 -d "=")
   YP=${YP#*\.}
   YP=${YP:0:2}
   YP=${YP#0}
   TP=$(grep "^OSDTopP =" /etc/vdr/setup.conf | cut -f 2 -d "=")
   TP=${TP#*\.}
   TP=${TP:0:2}
   TP=${TP#0}
   LP=$(grep "^OSDLeftP =" /etc/vdr/setup.conf | cut -f 2 -d "=")
   LP=${LP#*\.}
   LP=${LP:0:2}
   LP=${LP#0}
   XRES=${RES%x*}
   [ $XRES -gt 1920 ] && XRES=1920
   YRES=${RES#*x}
   [ $YRES -gt 1080 ] && YRES=1080
   DX=$(($XRES*$XP/100))
   DY=$(($YRES*$YP/100))
   OX=$(($XRES*$LP/100))
   OY=$(($YRES*$TP/100))
   sed -i /etc/vdr/setup.conf -e "s/^xine.osdExtent.X =.*/xine.osdExtent.X = ${XRES}/" -e "s/^xine.osdExtent.Y =.*/xine.osdExtent.Y = ${YRES}/"  \
                              -e "s/OSDWidth =.*/OSDWidth = ${DX}/" -e "s/OSDHeight =.*/OSDHeight = ${DY}/" \
                              -e "s/OSDTop =.*/OSDTop = ${OX}/" -e "s/OSDLeft =.*/OSDLeft = ${OY}/" \
                              -e "s/xineliboutput.OSD.Size = .*/xineliboutput.OSD.Size = ${RES}/"
   if [ "$(grep "xine.osdExtent.X" /etc/vdr/setup.conf)" = "" ] ; then
      echo "xine.osdExtent.X = ${XRES}" >> /etc/vdr/setup.conf
      echo "xine.osdExtent.Y = ${YRES}" >> /etc/vdr/setup.conf
   fi
   if [ "$(grep "Identifier.*\"${NEW_SCREEN}\"" $X_CFG)" != "" ] ; then
      sed -i $X_CFG -e "s/Screen [ ]*0.*/Screen 0 \"${NEW_SCREEN}\"/"
   fi
fi

if [ $XRES -gt 1000 ] ; then
   IH=170
   IW=220
else
   IH=80
   IW=120
fi
if [ "$(pidof vdr)" != "" ] ; then
   /etc/init.d/vdr stop
   STT=1
fi
sed -i /etc/vdr/setup.conf -e "s/skinenigmang.ChannelLogoHeight.*/skinenigmang.ChannelLogoHeight = $IH/" \
                           -e "s/skinenigmang.ChannelLogoWidth.*/skinenigmang.ChannelLogoWidth = $IW/"
