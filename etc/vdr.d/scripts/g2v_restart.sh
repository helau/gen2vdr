#!/bin/sh
source /_config/bin/g2v_funcs.sh

NUM_RESTARTS=0
if [ -f $ADMIN_EXEC_SCRIPT ] ; then
   sh $ADMIN_EXEC_SCRIPT
   rm -rf $ADMIN_EXEC_SCRIPT
   rm -rf $RUNVDR_RUN
   source /etc/vdr.d/conf/vdr
else
   if [ -f $VDR_START_FILE ] ; then
      ACT_DATE=$(date +%s)
      FDATE=$(ls -l --time-style=+%s $VDR_START_FILE | tr -s ' ' |cut -f6 -d ' ')
      DIFF=$(($ACT_DATE - $FDATE))
      if [ $DIFF -le 100 ] ; then
         sleep 2
         LAST_RESTARTS="$(cat $VDR_START_FILE)"
         if [ "$LAST_RESTARTS" = "" ] ; then
            NUM_RESTARTS=1
         else
            NUM_RESTARTS=$(($LAST_RESTARTS+1))
         fi
         if [ $WATCHDOG_REBOOT -gt 0 ] && [ $NUM_RESTARTS -ge $WATCHDOG_REBOOT ] ; then
            # Bailing out - stoppping vdr
            set -x
            touch $STOPVDR_FILE
            screen -dm sh -c "reboot"
         elif [ $NUM_RESTARTS -gt 1 ] ; then
            SV=$(($NUM_RESTARTS - 1))
            if [ -f $ADMIN_CFG_FILE.save.$SV ] ; then
               glogger -s "VDR restarting too fast - NOT trying $ADMIN_CFG_FILE.save.$SV"
#               cp -f $ADMIN_CFG_FILE.save.$SV $ADMIN_CFG_FILE >/dev/null 2>&1
#               sh $ADMIN_SCRIPT_PATH/admin_changes.sh -f
#               if [ -f $ADMIN_EXEC_SCRIPT ] ; then
#                  sh $ADMIN_EXEC_SCRIPT
#                  rm -rf $ADMIN_EXEC_SCRIPT
#                  rm -rf $RUNVDR_RUN
#                  source /etc/vdr.d/conf/vdr
#               fi
            fi
         fi
      else
         /_config/bin/g2v_updadminconf.sh -c
      fi
   fi
fi
echo "$NUM_RESTARTS" > $VDR_START_FILE

# remove temporary files
rm -rf /tmp/mpg-cache/* > /dev/null 2>&1 &
rm -rf /tmp/images/* > /dev/null 2>&1 &

# restart dvb driver
#if [ "$DVB_RESET" = "1" ] ; then
#   /_config/bin/dvbmod unload
#   /_config/bin/dvbmod load
#
#   if [ $DVB_CARD_NUM -gt 0 ] ; then
#      for i in $(seq 1 20) ; do
#         if [ $(ls -l /dev/dvb | grep adapter | wc -l 2>/dev/null) -ge $DVB_CARD_NUM ] ; then
#            break
#         fi
#         echo "Waiting for $DVB_CARD_NUM DVB devices ..."
#         sleep 1
#      done
#   fi
#fi

# check for valid vdr.conf and admin.conf
cp /etc/vdr.d/conf/vdr /tmp/vdr.conf
bash /etc/vdr/plugins/admin/setvdrconf.sh "" /tmp/vdr.conf
if [ $(grep "^[A-Z]" /tmp/vdr.conf | wc -l) -gt $(grep "^[A-Z]" /etc/vdr.d/conf/vdr | wc -l) ] ; then
   bash /etc/vdr/plugins/admin/setvdrconf.sh
elif [ $(grep "^[A-Z]" /tmp/vdr.conf | wc -l) -lt $(grep "^[A-Z]" /etc/vdr.d/conf/vdr | wc -l) ] ; then
   bash /etc/vdr/plugins/admin/setadmconf.sh
fi

# create Logs
if [ $NUM_RESTARTS -lt 3 ] ; then
   DT=$(date +%m%d%H%M)
   screen -dm sh -c "/_config/bin/g2v_log.sh /log/g2v_log_$DT"
fi

# kill xine if still running
[ "$(pidof xine)" != "" ] && screen -dm sh -c "sleep 5; killall -9 xine"
#[ "$(pidof -x vdr-softhd.sh)" != "" ] && screen -dm sh -c "kill -9 $(pidof -x vdr-softhd.sh)"
