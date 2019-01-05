#!/bin/bash
source /_config/bin/g2v_funcs.sh
# Activy set Display text
#set -x
if [ "$(ps x | grep vdr | grep "plugin=alcd ")" != "" ] ; then
   DONE=""
   svdrps PLUG alcd LOCK
   svdrps PLUG alcd PWRLED BLINK
#   if [ -s $WAKEUP_FILE ] ; then
#      NT=$(cat $WAKEUP_FILE | cut -f 1 -d ";")
#      WT="$(date -d "1970-01-01 UTC $NT seconds" '+%d.%m.%Y - %R')"
#      CH=$(cat $WAKEUP_FILE | cut -f 2 -d ";")
#      PR=$(cat $WAKEUP_FILE | cut -f 3- -d ";" | cut -b 1-20)
#      glogger -s "Timer: $WT $CH-$PR"
#      DONE=$(svdrpsend.pl PLUG alcd SHOW "$WT $PR" | grep "^900")
#      if [ "$DONE" = "" ] ; then
#         /bin/stty 38400 < /dev/ttyS0
#         echo -ne "\x9A\x02 $WT " > /dev/ttyS0
#         echo -ne "\x9A\x03 $CH-$PR " > /dev/ttyS0
#         glogger -s "Error writing timer to alcd"
#      fi
#      svdrps PLUG alcd STAY ON
#  fi
fi
