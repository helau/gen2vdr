#!/bin/bash
source /_config/bin/g2v_funcs.sh

NOAD_SCRIPT="${VIDEO}/noad.sh"

DAILY_WAKEUP=0
TIMER_WAKEUP=0

# Ist es der taeglicher Wakeup ?
if [ "$WAKEUP_DURATION" != "" -a $WAKEUP_DURATION -gt 0 ] ; then
   ACT_HOUR=$(date +%k)
   ACT_MINUTE=$(date +%M)
   if [ $WAKEUP_HOUR -eq $ACT_HOUR ] && [ $ACT_MINUTE -lt 10 ] ; then
      DAILY_WAKEUP=1
   elif [ $ACT_MINUTE -gt 50 ] ; then
      if [ $ACT_HOUR -eq 23 -a $WAKEUP_HOUR -eq 0 ] || [ $(($WAKEUP_HOUR -$ACT_HOUR)) -eq 1 ] ; then
         DAILY_WAKEUP=1
      fi
   fi
fi

if [ -f $WAKEUP_FILE ] ; then
   ACT_DATE=$(date +%s)
   FDATE=$(ls -l --time-style=+%s $WAKEUP_FILE | tr -s ' ' |cut -f6 -d ' ')
   DIFF=$(($ACT_DATE - $FDATE))
   if [ $DIFF -le 500 ] && [ $DIFF -ge -500 ]; then
      TIMER_WAKEUP=1
   fi
#   rm -f $WAKEUP_FILE
fi

logger "Wakeup: <$DAILY_WAKEUP-$TIMER_WAKEUP>"

if [ -s $NOAD_SCRIPT ] ; then
   echo "rm -rf $NOAD_SCRIPT" >> $NOAD_SCRIPT
   screen -dm sh -c "sh $NOAD_SCRIPT"
fi
if [ "$DAILY_WAKEUP" = "1" ] ; then
   TTW=$(($WAKEUP_DURATION * 60))
   screen -dm sh -c "sleep $TTW && $SVDRPCMD HITK Power"
elif [ "$TIMER_WAKEUP" = "1" ] ; then
   # Send Power key for shutting down after Timer
   svdrps MESG "Sende PowerTaste fuer Shutdown nach Timer"
   sleep 3
   svdrps HITK Back
   svdrps HITK Power
else
   # Remember last manual Startup
   touch $MANSTART_FILE
fi
