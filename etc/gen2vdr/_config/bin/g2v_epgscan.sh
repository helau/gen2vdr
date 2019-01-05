#!/bin/bash
source /_config/bin/g2v_funcs.sh

EPG_STAT_FILE="/video/~epgscan"

if [ "$1" != "-f" ] && [ -f $EPG_STAT_FILE ] ; then
   FDAY=$(ls -l --time-style=+%d $EPG_STAT_FILE | tr -s ' ' |cut -f6 -d ' ')
   ACT_DAY=$(date +%d)
   if [ "$FDAY" = "$ACT_DAY" ] ; then
      glogger -s "Heute wurde schon epg-gescanned"
      exit
   fi
fi

# Get epgdata via epgscan or tvm2vdr
if [ "$EPGSCAN" = "TVMovie" ] ; then
   svdrps PLUG tvm2vdr main
elif [ "$EPGSCAN" = "EPGScan" ] ; then
   svdrps MESG "Starte EPG-Scan ..."
   svdrps SCAN
fi
touch $EPG_STAT_FILE
