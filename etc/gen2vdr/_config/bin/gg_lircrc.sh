#!/bin/bash
source /_config/bin/g2v_funcs.sh
LDIR="/etc/gen2vdr/remote/act"
APPL=""

if [ "$1" != "" ] ; then
   APPL="$1"
else
   if [ "$(pidof ratpoison)" != "" ; then
      ACT_WIN="$(ratpoison -c info)"
      if [ "${ACT_WIN/*(_*_)/}" != "" ] ; then
         if [ "${ACT_WIN/*) 0(*/}" = "" ] ; then
            APPL="G2V-Launcher"
            glogger -s "GG title <$APPL>"
            ratpoison -c "title _${APPL}_"
         fi
      else
         APPL="${ACT_WIN#*(_}"
         APPL="${APPL%_)*}"
      fi
   fi
fi

if [ -e $LDIR -a "$APPL" != "" ] ; then
   NEXT_IR_RC="${LDIR}/${APPL}.conf"
   [ ! -e $NEXT_IR_RC ] && NEXT_IR_RC="${LDIR}/default.conf"
   [ ! -e $NEXT_IR_RC ] && NEXT_IR_RC="${LDIR}/minimal.conf"
   if [ -e $NEXT_IR_RC ] ; then
      if [ -e "${LDIR}/config" ] ; then
         source "${LDIR}/config"
         DAEMON=$(which inputevxd)
         killall -9 $DAEMON
         for i in $DEVICE ;  do
            CMD="$DAEMON -g -d $i -c $NEXT_IR_RC"
            glogger -s "Starting $CMD"
            $CMD
         done
      else
         DAEMON=$(which irexec)
         killall -9 $DAEMON
         CMD="$DAEMON --daemon $NEXT_IR_RC"
         glogger -s "Starting $CMD"
         $CMD
      fi
   fi
else
   glogger -s "Not switching remote <${ACT_IR_RC}><$NEXT_IR_RC>"
fi
