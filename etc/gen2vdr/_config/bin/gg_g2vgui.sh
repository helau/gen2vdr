#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh
glogger "Starte $0"

StartDefApp() {
   if [ "$(grep "Extension .Composite. is enabled" /log/Xorg.0.log)" != "" ] ; then
      [ "$(pidof xcompmgr)" == "" ] && screen -dm sh -c "xcompmgr -d:0 -s"
      screen -dm sh -c "/_config/bin/gg_switch.sh"
      sleep 3
   fi
   if [ -f  /etc/gen2vdr/applications/01.* ] ; then
      DEF_APP=$(ls /etc/gen2vdr/applications/01.*)
      APP=${DEF_APP##*\.}
      glogger "Starte $APP"
      screen -dm sh -c "/_config/bin/gg_switch.sh $APP"
   else
      glogger "Starte ratpoison"
      [ "$(pidof ratpoison)" == "" ] && screen -dm sh -c "ratpoison -d $DISPLAY"
   fi
}

StartActApp() {
   ACT_APP=$(cat "$GG_ACTAPP_FILE")
   glogger "Starte ActApp $ACT_APP"
   screen -dm sh -c "/_config/bin/gg_switch.sh $ACT_APP"
}

StartDefApp
sleep 10
IDX=0
while [ 1 ] ; do
   if [ "$IDX" == 0 ] ; then
      sleep 3
   else
      sleep 0.5
   fi
   if [ "$(ps x | grep "/_config/bin/gg_.*\.sh [0-9]")" == "" -a "$(pidof ratpoison)" == "" ] ; then
      if [ $IDX -gt 10 ] ; then
         StartActApp
         sleep 10
         IDX=0
      else
         IDX=$((IDX+1))
      fi
   else
      IDX=0
   fi
done
