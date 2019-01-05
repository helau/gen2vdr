#!/bin/bash
source /_config/bin/g2v_funcs.sh
LDB="/etc/gen2vdr/remote/act"
APPL="$1"

glogger -s "$0 $1"
MPIDS=$(pidof -x "$0" -o $$ -o $PPID -o %PPID)
for i in 1 2 3 4 5 ; do
   [ "$MPIDS" == "" ] && break
   sleep 1
   MPIDS=$(pidof -x "$0" -o $$ -o $PPID -o %PPID)
done
if [ "$MPIDS" != "" ] ; then
   glogger -s "Killing $0 $MPIDS"
   kill -9 $MPIDS
fi
if [ "$APPL" != "VDR" -a "$APPL" != "" ] ; then
   svdrps REMO off
   /usr/bin/dbus-send --system --type=method_call --dest=de.tvdr.vdr /Remote remote.Disable
   /_config/bin/gg_setsofthdd.sh DETA
   sleep 2
fi

killall -9 unclutter

if [ "$APPL" == "G2V-Launcher" -o "$APPL" == "VDR" ] ; then
   screen -dm sh -c "unclutter -d $DISPLAY -root -idle 0"
fi
/_config/bin/gg_setxdef.sh
KILLED=0
if [ "$APPL" != "" ] ; then
   for LDIR in $LDB ${LDB}[0-9] ; do
      [ ! -d $LDIR ] && continue
      NEXT_RC="${LDIR}/${APPL##*/}.conf"
      [ ! -e $NEXT_RC ] && NEXT_RC="${LDIR}/default.conf"
      [ ! -e $NEXT_RC ] && NEXT_RC="${LDIR}/minimal.conf"
      if [ "$KILLED" == "0" ] ; then
         killall -9 inputevxd irexec
         KILLED=1
      fi
      if [ -e $NEXT_RC ] ; then
         if [ -e "${LDIR}/config" ] ; then
            REPEAT_DELTA=0
            REPEAT_DELAY=0
            source "${LDIR}/config"
            DAEMON=$(which inputevxd)
            PARMS="-g -c $NEXT_RC"
            [ "$REPEAT_DELTA" == "0" ] && REPEAT_DELTA=$(grep RcRepeatDelta /etc/vdr/setup.conf 2>/dev/null| cut -f 2 -d "="|tr -d " ")
            [ "$REPEAT_DELAY" == "0" ] && REPEAT_DELAY=$(grep RcRepeatDelay /etc/vdr/setup.conf 2>/dev/null| cut -f 2 -d "="|tr -d " ")
            [ "$REPEAT_DELAY" != "" ] && PARMS="$PARMS -R $REPEAT_DELAY -r $REPEAT_DELTA"
            if [ "$DEVICE" == "" -a $(cat /proc/uptime |cut -f 1 -d ".") -lt 200 ] ; then
               svdrps MESG "Warte auf FB-Empfaenger ..."
               for i in $(seq 1 20) ; do
                  sleep 2
                  source "${LDIR}/config"
                  [ "$DEVICE" != "" ] && break
               done
               if [ "$DEVICE" == "" ] ; then
                  svdrps MESG "FB-Empfaenger kann nicht initialisiert werden"
               else
                  svdrps MESG "FB-Empfaenger ist einsatzbereit"
               fi
            fi
            for i in $DEVICE ;  do
               CMD="$DAEMON -d $i $PARMS"
               glogger -s "Starting $CMD"
               $CMD
               sleep 2
               if [ "$(ps x | grep $DAEMON | grep "$CMD")" == "" ] ; then
                  glogger -s "Error starting $CMD - restarting"
                  $CMD
               else
                  glogger -s "Started $CMD"
               fi
            done
         else
            DAEMON=$(which irexec)
            CMD="$DAEMON --daemon $NEXT_RC"
            glogger -s "Starting $CMD"
            $CMD
            sleep 2
            if [ "$(ps x | grep $DAEMON | grep "$CMD")" == "" ] ; then
               glogger -s "Error starting $CMD - restarting"
               $CMD
            else
               glogger -s "Started $CMD"
            fi
         fi
      else
         glogger -s "Not found <$NEXT_RC>"
      fi
   done
fi
