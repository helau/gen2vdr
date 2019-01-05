#!/bin/bash
source /_config/bin/g2v_funcs.sh
NEXT_APPL_F="/tmp/.nextappl"
APP_DIR="/etc/gen2vdr/applications"
exit

ACT_WIN="$(ratpoison -c info)"
glogger -s "$0 $1 ActWin <$ACT_WIN>"
MPIDS=$(pidof -x "$0" -o $$ -o $PPID -o %PPID)
if [ "$MPIDS" != "" ] ; then
   glogger -s "Killing $0 $MPIDS"
   kill -9 $MPIDS
fi

glogger -s "$0 $*"

if [ -s "$NEXT_APPL_F" -a "$1" = "-switch" ] ; then
   LCHECKED="$(ls --full-time "$NEXT_APPL_F" | cut -f 6,7 -d " ")"
   ld=$(date -d "$LCHECKED" +"%s")
   ad=$(date +"%s")
   if [ $((ad - ld)) -lt 20 ] ; then
      NEXT_APPL="$(cat /tmp/.nextappl 2>/dev/null)"
      EXPORT DISPLAY=${DISPLAY:-:0.0}
      glogger -s "gg_switchhook - $NEXT_APPL"
      if [ "$NEXT_APPL" != "" ] ; then
         for i in 1 2 3 ; do
            ACT_WIN="$(ratpoison -c info)"
            if [ "${ACT_WIN/*(_*_)/}" != "" ] ; then
               if [ "${ACT_WIN/*) 0(*/}" = "" ] ; then
                  NEXT_APPL="G2V-Launcher"
               fi
               glogger -s "GG title <$NEXT_APPL> <$ACT_WIN>"
               ratpoison -c "title _${NEXT_APPL}_"
               break
            elif [ "${ACT_WIN/*) 0(*/}" = "" ] ; then
               NEXT_APPL="G2V-Launcher"
               glogger -s "GG title <$NEXT_APPL>"
               ratpoison -c "title _${NEXT_APPL}_"
               break
            else
               glogger -s "GG title ignore <$ACT_WIN>"
            fi
            sleep 2
         done
      fi
   fi
fi


if [ "${ACT_WIN/*(_*_)/}" != "" ] ; then
   if [ "${ACT_WIN/*) 0(*/}" = "" ] ; then
      APPL="G2V-Launcher"
      glogger -s "GG title <$APPL>"
      ratpoison -c "title _${APPL}_"
   else
      APPL=""
   fi
else
   APPL="${ACT_WIN#*(_}"
   APPL="${APPL%_)*}"
fi

/_config/bin/gg_setactapp.sh $APPL
