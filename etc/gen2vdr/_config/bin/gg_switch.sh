#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh

APPL_DIR="/etc/gen2vdr/applications"
NEXT_APPL="/tmp/.nextappl"

MPIDS=$(pidof -x "$0" -o $$ -o $PPID -o %PPID)
if [ "$MPIDS" != "" ] ; then
   glogger -s "Killing $0 $MPIDS"
   kill -9 $MPIDS
fi

glogger -s "gg_switch <$1>"

#if [ "$(rc-status -a|grep g2vgui)" == "" ] ; then
#   glogger -s "GUI not activated"
#   exit
#fi

IDX=0
while [ "$(pidof X)" == "" ] ; do
   if [ $IDX -gt 30 ] ; then
      glogger -s "X is not started"
      exit
   fi
   [ "$IDX" == 0 ] && glogger -s "Waiting for X"
   sleep 1
   IDX=$((IDX+1))
done
if [ $IDX -gt 0 ] ; then
   glogger -s "X was started after $IDX seconds"
   sleep 3
fi
ACT_APP=$(ps x |grep /_config/bin/gg_startapp.sh |grep SCREEN|head -n 1)
ACT_WIN=${ACT_APP##* }

cd $APPL_DIR

CMD=${1#/}

if [ "$CMD" = "-switch" ] ; then
   if [ "${ACT_WIN:0:2}" = "01" ] ; then
      CMD=$(ls 02.*)
   else
      CMD=$(ls 01.*)
   fi
   [ ! -f $CMD ] && CMD=""
elif [ "$CMD" != "" ] ; then
   if [ ! -f "$CMD" -a "$CMD" != "" ] ; then
      if [ "${CMD#*/}" = "$CMD" ] ; then
         CC="$(ls *.$CMD 2>/dev/null)"
         if [ "$CC" = "" ] ; then
            CC="$(ls */*.$CMD 2>/dev/null)"
         fi
      else
         CC="$(ls "${CMD/\//\/*.}")"
      fi
      if [ "$CC" != "" -a -f "$CC" ] ; then
         CMD=$CC
      else
         glogger -s "GUIAPP <$CMD> not found <$CC>"
         CMD=""
      fi
   fi
fi

echo "$CMD" > $GG_ACTAPP_FILE

if [ "$ACT_WIN" != "" -a "$CMD" != ""  ] ; then
   if [ "$(ps x |grep /_config/bin/gg_startapp.sh |grep "$CMD")" != "" ] ; then
      glogger -s "<$CMD> is already active"
      exit
   fi
fi

ALL_APPS=$(/_config/bin/getproctree.sh /_config/bin/gg_startapp.sh)
if [ "$ALL_APPS" != "" ] ; then
   kill $ALL_APPS > /dev/null 2>&1
   for i in 1 2 3 ; do
      APPS=$(/_config/bin/getproctree.sh /_config/bin/gg_startapp.sh)
      [ "$APPS" = "" ] && break
      kill $APPS > /dev/null 2>&1
      sleep 1
   done
   kill -9 $ALL_APPS > /dev/null 2>&1
fi

if [ "$CMD" != "" ] ; then
   glogger -s "Starting <$CMD>"
   set -x
   exec 1> >(logger -s) 2>&1
   for i in 1 2 3 4 5 ; do
      screen -dm sh -c "/_config/bin/gg_startapp.sh $CMD"
      glogger -s "Started start <$CMD>"
      sleep 3
      if [ "$(ps x |grep /_config/bin/gg_startapp.sh |grep "$CMD")" != "" ] ; then
         glogger -s "<$CMD> was started sucessfully"
         break
      fi
   done
   if [ "$(ps x |grep /_config/bin/gg_startapp.sh |grep "$CMD")" == "" ] ; then
      glogger -s "<$CMD> could not be started"
   fi
else
   if [ "$(pidof ratpoison)" == "" ] ; then
      screen -dm sh -c "ratpoison -d $DISPLAY"
   else
      ACT_SES="$(ratpoison -c windows |grep "Gg_launcher"| cut -f 1 -d "_")"
      if [ "$ACT_SES" == "" ] ; then
         glogger -s "Starting gg_launcher.pl"
         ratpoison -c "exec /_config/bin/gg_launcher.pl"
      else
         glogger -s "Switch to session -${ACT_SES}"
         ratpoison -c "select $ACT_SES"
      fi
   fi
   screen -dm sh -c "/_config/bin/gg_setactapp.sh G2V-Launcher"
fi
