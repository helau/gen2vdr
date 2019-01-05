#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
APPL_DIR="/etc/gen2vdr/applications"
NEXT_APPL="/tmp/.nextappl"

CMD="${1#/}"
glogger -s "gg_switchapp <$1>"

cd $APPL_DIR

if [ "$CMD" != "" -a -f "$CMD" ] ; then
   USER=${CMD%.*}
   USER=${USER##*/}
   USER=${USER##*.}
   APPL=${CMD##*.}
   SW_FILE="sessions/${APPL}.switch"
   if [ "${CMD#*/}" != "$CMD" ] ; then
      SD="${CMD%%/*}"
      APPL="${SD#*.}/$APPL"
   fi
   rm -f $NEXT_APPL
   /_config/bin/gg_setactapp.sh ${APPL##*.}
   if [ $(ps -ef |grep "${APPL_DIR}/$CMD"|wc -l) -gt 1 ] ; then
      glogger -s "Already running <$CMD>"
      SS="$(cat $SW_FILE)"
      ACT_SES="$(ratpoison -c windows |grep "${SS}"| cut -f 1 -d "_")"
      ratpoison -c "select $ACT_SES"
   else
      ST=$(date +%s)
      glogger -s "Starting <$CMD><$APPL> with user <$USER>"
      echo "${APPL}" > $NEXT_APPL
      su $USER -c "${APPL_DIR}/$CMD"
      ET=$(date +%s)
      if [ $(($ET - $ST)) -lt 10 ] ; then
         /_config/bin/gg_setactapp.sh G2V-Launcher
      fi
   fi
else
   glogger -s "Unknown CMD - activating Launcher"
fi
