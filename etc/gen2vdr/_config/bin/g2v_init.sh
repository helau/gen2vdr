#!/bin/bash

#set -x; exec 1> >(logger -s) 2>&1      # Debug!

source /_config/bin/g2v_funcs.sh

SVDRPCMD="/usr/bin/svdrpsend.sh"
DAILY_WAKEUP=0
TIMER_WAKEUP=0
DO_REBOOT=0

function check_start() {
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
      if [ $DIFF -le 500 ] && [ $DIFF -ge -500 ] ; then
         TIMER_WAKEUP=1
      fi
#     rm -f $WAKEUP_FILE
   fi

   glogger "Wakeup: <$DAILY_WAKEUP-$TIMER_WAKEUP>"
}

send_power_key() {      # Nachricht anzeigen und VDR herunterfahren
   $SVDRPCMD MESG $MESG
   sleep 3
   $SVDRPCMD HITK Back
   $SVDRPCMD HITK Power
}

[ "$(pidof -x vdrshutdown.sh)" != "" ] && exit

check_start
sleep 20
MESG=""
if [ "$DAILY_WAKEUP" = "1" ] && [ $WAKEUP_DURATION -gt 0 ] ; then
   MESG="Sende PowerTaste fuer Shutdown nach DailyWakeup"
elif [ "$TIMER_WAKEUP" = "1" ] ; then
   MESG="Sende PowerTaste fuer Shutdown nach Timer"
   send_power_key # Nachricht anzeigen und VDR herunterfahren
else
   # Remember last manual Startup
   touch $MANSTART_FILE
fi
#[ "$MESG" != "" ] && send_power_key # Nachricht anzeigen und VDR herunterfahren
# Get epgdata via epgscan or tvm2vdr
screen -dm sh -c "sh /_config/bin/g2v_epgscan.sh"

if [ "$WATCHDOG" = "0" ] ; then
   DO_RESTART=1
   for i in 1 2 3 4 5 6 7 8 9 ; do
      if [ "$($SVDRPCMD volu | grep "^250")" != "" ] ; then
         DO_RESTART=0
         break
      fi
      sleep 15
   done
   if [ "$DO_RESTART" = "1" ] ; then
      glogger -s "VDR does not respond - Restarting"
      /etc/init.d/vdr stop
      kill -9 $(pidof vdr runvdr)
      /etc/init.d/vdr start

      if [ ! -f /etc/vdrReboot ] && [ ! -f /tmp/.shutdown ] && [ "DO_REBOOT" == "1" ] ; then
         sleep 10
         for i in 1 2 3 4 5 ; do
            if [ "$($SVDRPCMD volu | grep "^250")" != "" ] ; then
               DO_REBOOT=0
               break
            fi
         done
         if [ "$DO_REBOOT" = "1" ] ; then
            glogger -s "VDR still does not respond - Rebooting"
            touch /etc/vdrReboot
            screen -dm sh -c "reboot"
            exit
         fi
      fi
   fi
fi

# Update vdr channels
[ "$(rc-status -a|grep mediatomb|grep started)" != "" ] && screen -dm sh -c "sleep 30; bash /_config/bin/g2v_mtvdrch.sh"

[ -f /etc/vdrReboot ] && rm /etc/vdrReboot

#if [ "$(fgconsole)" != "7" -o "$(pidof -x /_config/bin/gg_launcher.pl /_config/bin/gg_startapp.sh)" = "" ] ; then
#   /etc/init.d/g2vgui stop
#   /etc/init.d/g2vgui start
#fi

if [ "$DAILY_WAKEUP" = "1" ] && [ $WAKEUP_DURATION -gt 0 ] ; then
   sleep $(($WAKEUP_DURATION * 60)) # WAKEUP_DURATION ist in Minuten
   send_power_key # Nachricht anzeigen und VDR herunterfahren
fi

glogger "Finished"
