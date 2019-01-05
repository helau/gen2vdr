#!/bin/bash
source /_config/bin/g2v_funcs.sh

export LANG="de_DE.UTF-8"
export VDR_LANG="de_DE.UTF-8"

[ ! -d $EPG_IMAGES ] && mkdir $EPG_IMAGES
touch $EPG_IMAGES/.keep

[ -f $STOPVDR_FILE ] && rm $STOPVDR_FILE
echo 0 > $VDR_START_FILE

#if [ "$DVB_CARD_NUM" = "" ] ; then
#   sh /_config/bin/detect_dvb.sh
#   source /etc/vdr.d/conf/vdr
#elif [ $DVB_CARD_NUM -gt 0 ] ; then
#   screen -dm sh -c "/_config/bin/dvbmod load"
#fi

# check for valid vdr.conf and admin.conf
cp /etc/vdr.d/conf/vdr /tmp/vdr.conf
bash /etc/vdr/plugins/admin/setvdrconf.sh "" /tmp/vdr.conf
if [ $(grep "^[A-Z]" /tmp/vdr.conf | wc -l) -gt $(grep "^[A-Z]" /etc/vdr.d/conf/vdr | wc -l) ] ; then
   bash /etc/vdr/plugins/admin/setvdrconf.sh
   source /etc/vdr.d/conf/vdr
elif [ $(grep "^[A-Z]" /tmp/vdr.conf | wc -l) -lt $(grep "^[A-Z]" /etc/vdr.d/conf/vdr | wc -l) ] ; then
   bash /etc/vdr/plugins/admin/setadmconf.sh
   source /etc/vdr.d/conf/vdr
fi

[ -e /_config/bin/setscart.sh ] && sh /_config/bin/setscart.sh DVB &
[ -e /_config/bin/rvdrinit.sh ] && sh /_config/bin/rvdrinit.sh

if [ -f $ADMIN_EXEC_SCRIPT ] ; then
   sh $ADMIN_EXEC_SCRIPT
   rm -rf $ADMIN_EXEC_SCRIPT > /dev/null 2>&1 &
   source /etc/vdr.d/conf/vdr
fi

if [ $LOG_LEVEL -gt 2 ] ; then
   #activate coredumping if debug is enabled
   [ ! -d /tmp/corefiles ] && mkdir /tmp/corefiles
   chmod 777 /tmp/corefiles
   echo "/tmp/corefiles/core" > /proc/sys/kernel/core_pattern
   echo "1" > /proc/sys/kernel/core_uses_pid
   ulimit -c unlimited
   locale -v |logger
   env |logger
fi

#Build commands.conf
if [ -d /etc/vdr/commands ] ; then
   for i in  /etc/vdr/commands/[0-9]* ; do
      [ "${i/*\.*/}" == "" ] && continue
      if [ "$CMDSUBMENU" = "1" ] ; then
         echo "${i/*_/} {"
         cat $i | sed -e "s/^\([^$]\)/  \1/"
         echo "  }"
      else
         cat $i
      fi
      echo ""
   done > /etc/vdr/commands.conf
fi

#Build reccmds.conf
if [ -d /etc/vdr/reccmds ] ; then
   for i in  /etc/vdr/reccmds/* ; do
      cat $i
      echo ""
   done > /etc/vdr/reccmds.conf
fi

if [ $DVB_CARD_NUM -gt 0 ] ; then
   STAT_FILE="/_config/status/card_not_found"
   NUMRESTARTS=0
   [ -s "${STAT_FILE}" ] && NUMRESTARTS=$(cat "${STAT_FILE}")
   FOUND=0
   for i in $(seq 1 20) ; do
      if [ $(ls -l /dev/dvb/ad*/frontend* | wc -l 2>/dev/null) -ge $DVB_CARD_NUM ] ; then
         FOUND=1
         break
      fi
      echo "Waiting for $DVB_CARD_NUM DVB devices ..."
      sleep 1
   done
   if [ "$FOUND" == "0" ] ; then
      NUMRESTARTS=$((NUMRESTARTS+1))
      echo "$NUMRESTARTS" > "$STAT_FILE"
      logger -s "No DVB cards found - number $NUMRESTARTS"
      if [ "$NUMRESTARTS" -le 5 ] ; then
         logger -s "Restarting"
         screen -dm sh -c "shutdown -r now"
         exit
      fi
   fi
   echo "0" > "$STAT_FILE"
#   if [ "$(lsmod |grep "ddbridge")" != "" -a "$(ls /dev/dvb/adapter*/ca*)" != "" ] ; then
#      echo "00 01" > /sys/class/ddbridge/ddbridge0/redirect
#   fi
fi
if [ "$(pidof ratpoison)" == "" ] || [ "$(ratpoison -d :0 -c info | grep -i gg_launcher)" != "" ] ; then
   screen -dm sh -c "/_config/bin/gg_switch.sh VDR"
fi
# for fucking Umlauts
export LC_COLLATE="de_DE.UTF-8"
export LC_NUMERIC="de_DE.UTF-8"
