#!/bin/bash
source /_config/bin/g2v_funcs.sh
FRV_CON=7
VDR_CON=8
FRV_DISABLE="/tmp/.freevodisabled"
VDR_DISABLE="/tmp/.vdrdisabled"

[ -f /tmp/.shutdown ] && exit

END=$1

if [ "$2" != "" ]; then
   END=$2
fi

if [ "$1" = "VDR" ] ; then
   for i in `seq 1 15` ; do
      if [ "$(pidof vdr)" != "" ] ; then
         break
      fi
      sleep 1
   done
   if [ "$(pidof vdr)" = "" ] ; then
      glogger -s "VDR ist nicht gestartet"
      exit
   fi
   rm -f $VDR_DISABLE > /dev/null 2>&1
   touch $FRV_DISABLE > /dev/null 2>&1
   FGC=$VDR_CON
else 
   FRV=""
   for i in `seq 1 15` ; do
      if [ "$(pidof -x /usr/bin/freevo)" != "" ] ; then
         break;
      fi
      sleep 1
   done
   if [ "$(pidof -x /usr/bin/freevo)" = "" ] ; then
      glogger -s "FreeVo ist nicht gestartet"
      exit
   fi
   rm -f $FRV_DISABLE > /dev/null 2>&1
   touch $VDR_DISABLE > /dev/null 2>&1
   FGC=$FRV_CON
fi
glogger -s "Waiting for $FGC"

SWITCHED=0

for i in $(seq 1 $END) ; do
   glogger -s "Waiting for $FGC $i $(fgconsole)"
   if [ -f $VDR_DISABLE ] && [ "$FGC" = "$VDR_CON" ]; then
      glogger -s "VDR disabled"
      break 
   fi
   
   if [ -f $FRV_DISABLE ] && [ "$FGC" = "$FRV_CON" ]; then
      glogger -s "Freevo disabled"
      break 
   fi
   
   if [ "$(fgconsole)" != "$FGC" ] ; then
      while [ "$(fgconsole)" != "$FGC" ] ; do
         glogger -s "Switching to console $FGC"
         killall -9 chvt > /dev/null 2>&1
         chvt $FGC &
         sleep 1
      done
      SWITCHED=$(($SWITCHED+1))
   fi
   if [ ${i} -gt 15 ] && [ $SWITCHED -ge 1 ] ; then
      glogger -s "Break out"
      break
   fi
   sleep 1
done
