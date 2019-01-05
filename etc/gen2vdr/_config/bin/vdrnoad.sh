#!/bin/bash
source /_config/bin/g2v_funcs.sh

NOAD="/usr/bin/noad"
# before opts
NOADBOPTS="--statisticfile=/var/log/noadonlinestat"
# after opts
NOADAOPTS="-p 15 --background --comments --jumplogo --ac3 --overlap --backupmarks --statisticfile=/var/log/noadstat --OSD"
NOADOPTS=""

if [ ! -s $NOAD ] ; then
   glogger -s "<$NOAD> not found"
   exit
fi

if [ "$SET_MARKS" = "Live" ] ; then
   NOADOPTS="--online=1"
else
   if [ "$SET_MARKS" = "Immer" ] ; then
      NOADOPTS="--online=2"
   fi
fi

case "$1" in
   before)
      if [ "$NOADOPTS" != "" ] ; then
         CMD="$NOAD $NOADOPTS $NOADBOPTS before \"$2\""
         glogger -s "Starting <$CMD>"
         screen -dm sh -c "$CMD"
      fi
      ;;
   after)
      CMD="$NOAD $NOADOPTS $NOADAOPTS after \"$2\""
      # Wait for other noads to end "
      while [ "$(pidof noad)" != "" ] ; do
         sleep 10
      done	 
      glogger -s "Starting <$CMD>"
      screen -dm sh -c "$CMD"
      ;;
   edited)
      ;;
   *)
      echo "ERROR: unknown state: $1"
      ;;
esac
