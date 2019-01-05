#! /bin/bash
source /_config/bin/g2v_funcs.sh
#

SLOW_DOWN_CDSPEED="cdspeed -s"
SLOW_DOWN_HDPARM="hdparm -E"

if [ "$1" = "-c" ] ; then
   if [ "$DISC_SLOWDOWN" != "Aus " ] ; then
      speed=$DISC_SPEED
   else
      speed=0
   fi
else
   speed=$1
fi
if [ "$2" != "" ] ; then
   dev=$2
else
   dev="/dev/cdrom"
fi

if [ $speed -gt 0 ] ; then
   if [ "$DISC_SLOWDOWN" = "hdparm" ] ; then
      cmd="hdparm -E $speed $dev"
   elif [ "$DISC_SLOWDOWN" = "cdspeed" ] ; then
      cmd="cdspeed -s $speed -d $dev"
   else
      cmd=""
   fi
   if [ "$cmd" != "" ] ; then
      glogger -s "CDSpeed: <$cmd>"
      $cmd
   fi
fi
