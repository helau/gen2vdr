#!/bin/bash
source /_config/bin/g2v_funcs.sh
APPL_DIR="/etc/gen2vdr/applications"
NEXT_APPL="/tmp/.nextappl"

CMD="${1#/}"
glogger -s "gg_startapp <$1>"

cd $APPL_DIR

if [ "$CMD" != "" -a -f "$CMD" ] ; then
   USER=${CMD%.*}
   USER=${USER##*/}
   USER=${USER##*.}
   APPL=${CMD##*.}
   if [ "${CMD#*/}" != "$CMD" ] ; then
      SD="${CMD%%/*}"
      APPL="${SD#*.}/$APPL"
   fi
   rm -f $NEXT_APPL
   if [ $(ps x |grep "${APPL_DIR}/$CMD"|wc -l) -gt 1 ] ; then
      glogger -s "Already running <$CMD>"
   else
      screen -dm sh -c "sleep 3; /_config/bin/gg_setactapp.sh ${APPL##*.}"
      if [ "${APPL##*.}" != "VDR" -a "${APPL##*.}" != "" ] ; then
         svdrps REMO off
         /usr/bin/dbus-send --system --type=method_call --dest=de.tvdr.vdr /Remote remote.Disable
         /_config/bin/gg_setsofthdd.sh DETA
         sleep 2
      fi

      ST=$(date +%s)
      glogger -s "Starting <$CMD><$APPL> with user <$USER>"
      echo "${APPL}" > $NEXT_APPL
      su $USER -c "${APPL_DIR}/$CMD"
      ET=$(date +%s)
#      if [ $(($ET - $ST)) -lt 10 ] ; then
#         /_config/bin/gg_setactapp.sh G2V-Launcher
#      fi
   fi
else
   glogger -s "Unknown CMD - activating Launcher"
fi
