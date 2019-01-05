#!/bin/bash
source /_config/bin/g2v_funcs.sh

logger -s "$0 $1"
#RC="$(/usr/bin/svdrpsend.sh plug softhddevice atta)"
RC="$(/_config/bin/gg_setsofthdd.sh atta)"

while [ 1 ] ; do
#   if [ "$(ratpoison -d :0.0 -c info | grep -i gg_launcher)" != "" ] ; then
#      screen -dm sh -c "/_config/bin/gg_switch.sh VDR"
#      break
#      RC="$(/usr/bin/svdrpsend.sh plug softhddevice atta)"
   if [ "$RC" == "" ] || [ "$(pidof vdr)" == "" ] || [ "${RC/*250*/}" != "" -a  "${RC/*900*/}" != "" -a "${RC/*220*/}" != "" ] ; then
#      /usr/bin/svdrpsend.sh plug softhddevice deta
#      sleep 1
      RC="$(/_config/bin/gg_setsofthdd.sh atta)"
#      /_config/bin/gg_setsofthdd.sh atta
   fi
   sleep 3
   ACT_WIN=$(ratpoison -d :0.0 -c windows | grep softhddevice)
   [ "${ACT_WIN/*_\*_*/}" != "" ] && ratpoison -d :0.0 -c "select ${ACT_WIN%%_*}"
done
