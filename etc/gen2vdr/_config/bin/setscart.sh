#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ "$1" != "DVB" ] && [ "$1" != "TVOUT" ] ; then
   echo "Illegal Parameter <$1> - must be DVB or TVOUT"
   exit
fi

BOARD=$(sh /_config/bin/query_mb.sh)

case "$BOARD" in
   MP_*)
      if [ "$MP_TVOUT" = "1" ] && [ "$(lsmod | grep "^fs450")" = "" ] ; then
         cd /_config/tvout
         sh install.sh
         ./set800X600.sh
      fi
   
      if [ "$GUI_SWITCH_OUTPUT" != "1" ] ; then
         echo "No Switch set"
         exit
      fi
      
      glogger -s "Switching MP-Scart $1"

      if [ "$1" = "DVB" ] ; then
         MP_PARM="--dvb"
      else 	 
         MP_PARM="--vga"
      fi
      /_config/bin/mp-switch-video $MP_PARM
      
      ;;
   ACTIVY)
      /_config/bin/activy_tvout.sh $1
      ;;
   *)      
      ;;
esac

