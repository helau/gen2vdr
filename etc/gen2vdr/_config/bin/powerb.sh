#!/bin/bash
# Skript which is executed when the powerbutton is pressed
source /_config/bin/g2v_funcs.sh

EJECT_CMD="/_config/bin/eject.sh"
if [ "$(pidof vdr)" != "" ] ; then
   HALT_CMD="/usr/bin/svdrpsend.sh HITK power"
else
   HALT_CMD="shutdown -r now"
fi
#set -x
CMD="$HALT_CMD"

if [ "${PB_FUNCTION}" = "EJECT" ] ; then
   CMD="$EJECT_CMD"
elif [ "${PB_FUNCTION/HALT_EJECT/}" = "" ] ; then
   PBTMP="/tmp/~pb"
   if [ -f $PBTMP ] ; then
      ACTDATE=$(date +%s)
      FDATE=$(ls -l --time-style=+%s $PBTMP | tr -s ' ' |cut -f6 -d ' ')
      DIFF=$(($ACTDATE - $FDATE))
      if [ $DIFF -le 2 ] ; then
         CMD=$EJECT_CMD
      fi
   fi
   touch $PBTMP
fi
glogger -s "Starte <$CMD>"
screen -dm sh -c "$CMD"
