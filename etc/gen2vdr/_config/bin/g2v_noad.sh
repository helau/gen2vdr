#!/bin/bash
source /_config/bin/g2v_funcs.sh

# check if called from vdr menu
if [ -d "$1" ] ; then
   screen -dm sh -c "$0 - \"$1\""
   exit
fi

NOAD="$(which noad)"

NICE_CMD="nice -n 19 ionice -c 3"
NOAD_CPUPERCENTAGE="50"

NOAD_CPULIMIT="cpulimit -b -l $NOAD_CPUPERCENTAGE -P $NOAD"

# before opts
NOAD_BOPTS="-vvv --statisticfile=/var/log/noadonlinestat before"
# after opts

NOAD_AOPTS="--comments --jumplogo --ac3 --overlap --backupmarks --statisticfile=/var/log/noadstat -"
NOAD_OPTS=""

if [ "$NOAD" = "" ] ; then
   glogger -s "<$NOAD> not found"
   exit
fi

case "$1" in
   before)
      if [ "$SET_MARKS" = "Live" ] ; then
         NOAD_OPTS="--online=1 $NOAD_BOPTS"
      elif [ "$SET_MARKS" = "Immer" ] ; then
         NOAD_OPTS="--online=2 $NOAD_BOPTS"
      fi
      shift
      ;;
   after|-)
      NOAD_OPTS="$NOAD_AOPTS"
      shift
      ;;
   *)
      echo "ERROR: unknown state: $1"
      exit
      ;;
esac
# Wait for other noads to end
if [ "$NOAD_OPTS" != "" ] ; then
   [ "$(pidof noad)" != "" ] && glogger -s "Waiting for noad ..."
   while [ "$(pidof noad)" != "" ] ; do
      sleep 10
   done
   CMD="$NICE_CMD $NOAD $NOAD_OPTS"
   glogger -s "Starting <$CMD $1>"
   glogger -s "NoAD process: CPU limited to "$NOAD_CPUPERCENTAGE"% <"$NOAD_CPULIMIT">"
   $NOAD_CPULIMIT
   $CMD "$1"
   glogger -s "NoAD process: CPU limitation ended"
   killall cpulimit
fi
