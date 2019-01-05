#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
for i in 1 2 3 4 5 6 7 8 9 0 ; do
   [ "$(pidof vdr)" != "" ] && break
   sleep 2
done
if [ "$(pidof vdr)" = "" ] ; then
   glogger "X2VDR - VDR not running"
   exit 1
fi
glogger -s $0
setterm -blank -powersave off -powerdown -cursor off -store

#xte "mousemove 2000 2000"
[ "$(pidof unclutter)" == "" ] && screen -dm sh -c "unclutter -d $DISPLAY -root -idle 1"

PARM=""
if [ "${PLUGINS/* xineliboutput */}" = "" -o "${PLUGINS/* xine */}" = "" ] ; then
   CMD="/_config/bin/vdr-xine.sh"
   PARM="$1"
elif [ "${PLUGINS/* dvbhddevice */}" = "" ] ; then
   CMD="/_config/bin/vdr-ffhd.sh"
elif [ "${PLUGINS/* softhddevice */}" = "" ] || [ "${PLUGINS/* vaapidevice */}" = "" ] ; then
   CMD="/_config/bin/vdr-softhd.sh"
fi

PIDS="$(pidof -x $CMD)"
[ "$PIDS" != "" ] && kill -9 $PIDS > /dev/null 2>&1
#screen -dm sh -c "svdrpsend.sh REMO on; /usr/bin/dbus-send --system --type=method_call --dest=de.tvdr.vdr /Remote remote.Enable"
screen -dm sh -c "/_config/bin/g2v_display.sh -vdr"
svdrps REMO on
/usr/bin/dbus-send --system --type=method_call --dest=de.tvdr.vdr /Remote remote.Enable | logger -s
glogger -s "Start <$CMD $PARM>"
$CMD $PARM
glogger -s "Exit <$CMD $PARM>"
[ "$(pidof -x $CMD)" != "" ] && kill -9 $(pidof -x $CMD)
glogger "X2VDR ended"
killall -9 unclutter >/dev/null 2>&1
