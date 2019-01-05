#!/bin/bash
source /_config/bin/g2v_funcs.sh
set -x
trap "" HUP INT QUIT TERM ABRT ALRM EXIT
# Log everything
LOG_FILE="/log/$(basename ${0%.*}).log"
echo "Started at: $(date +'%F %R')" > ${LOG_FILE}
exec 1> >(tee -a ${LOG_FILE}) 2>&1

[ "$BOOT_SPLASH" == "1" ] && source /_config/bin/g2v_splash.sh
[ -f /etc/conf.d/myhibernate.conf ] && source /etc/conf.d/myhibernate.conf

if [ "BOOT_SPLASH" == "1" ] ; then
   g2v_splash_exit
   g2v_splash_start "shutdown"
   g2v_splash_prog 100 100
   g2v_splash_prog 100 100
fi

touch /tmp/.shutdown
[ "$BOOT_SPLASH" == "1" ] && SPLASH_CON=$(fgconsole)

#sleep 3
# Module die entladen werden sollen
MOD_UNLOAD=${MOD_UNLOAD:=ddbridge ngene cxd2099 dvb_core stv6110x lnbp21 stv090x ngene}

# Boot-Services die gestoppt werden sollen
SVC_BOOT_STOP=${SVC_BOOT_STOP:=alsasound lircd}

# Default-Services die NICHT gestoppt werden sollen
SVC_DEF_STAY=${SVC_DEF_STAY:=hald dbus vixie-cron urandom keymaps ivman gpm consolefont acpid}

# Prozesse die beendet werden muessen
PROC_TO_KILL=${PROC_TO_KILL:=vdr-disable.sh vdr-enable.sh ntpdate umount mount vdr perl sshd}

# Services die zuerst/zuletzt beendet/gestartet werden
SVC_STOP_FIRST=${SVC_STOP_FIRST:=local vdr g2vgui xvdr xbmc}
SVC_STOP_LAST=${SVC_STOP_LAST:=lircd}
SVC_START_FIRST=${SVC_START_FIRST:=alsasound lircd staticroute vdr LCDd g2vgui}
SVC_START_LAST=${SVC_START_LAST:=local}

# In /etc/conf.d/myhibernate.conf koennen diese Parameter umgestellt werden - VORSICHT !!!

#svdrpsend.sh MESG "System wird heruntergefahren ..."

#logout all ssh users
#killall skill -KILL -v /dev/pts/*

# end vdr first
/etc/init.d/vdr stop
/etc/init.d/vdr zap
kill -9 $(pidof vdr) $(pidof -x runvdr) > /dev/null 2>&1

SVC_BOOT=$(find /etc/runlevels/boot/ -type l | cut -f 5 -d "/" |sort -u | tr "\n" " ")
SVC_DEFAULT=$(find /etc/runlevels/default/ -type l | cut -f 5 -d "/" |sort -u| tr "\n" " ")

#SVC_STARTED=$(ls -t /var/lib/init.d/started/[a-z]* | cut -f 6 -d "/"| tr "\n" " ")
SVC_STARTED=$(rc-status boot default |grep started|cut -f 2 -d " "| tr "\n" " ")
#SVC_STARTSEQ=$(ls -rt /var/lib/init.d/started/[a-z]* | cut -f 6 -d "/"| tr "\n" " ")

glogger -s "Running services: <$SVC_STARTED>"

#SVC_START_SEQ="$SVC_START_FIRST"
SVC_START_SEQ=""
SVC_STOP_SEQ=""

# calculate services to stop
for i in $SVC_STOP_FIRST ; do
   if ( strstr " $SVC_STARTED " " $i " ) ; then
      SVC_STOP_SEQ="$SVC_STOP_SEQ $i"
   fi
done

for i in $SVC_STARTED ; do
   if ( ! strstr " $SVC_BOOT $SVC_DEF_STAY $SVC_STOP_SEQ $SVC_STOP_LAST " " $i " ) ; then
      SVC_STOP_SEQ="$SVC_STOP_SEQ $i"
   fi
done

for i in $SVC_BOOT_STOP ; do
   if ( ! strstr " $SVC_STOP_SEQ $SVC_STOP_LAST " " $i " ) ; then
      SVC_STOP_SEQ="$SVC_STOP_SEQ $i"
   fi
done

for i in $SVC_STOP_LAST ; do
   if ( strstr " $SVC_STARTED " " $i " ) ; then
      SVC_STOP_SEQ="$SVC_STOP_SEQ $i"
   fi
done

glogger -s "Services to stop: <$SVC_STOP_SEQ>"
NUM_SVC=$(echo $SVC_STOP_SEQ | wc -w)
NUM_STEPS=$((NUM_SVC + 3))
IDX=$NUM_STEPS

for i in $SVC_STOP_SEQ ; do
   CON=$(fgconsole)
   glogger -s "Stopping >$i< >$CON<"
   IDX=$((IDX - 1))
#   g2v_splash_prog $IDX $NUM_STEPS $i
   /etc/init.d/$i stop
   /etc/init.d/$i zap
   [ "$BOOT_SPLASH" == "1" ] && [ "$CON" != "$SPLASH_CON" ] && killall -9 chvt 2>/dev/null && chvt $SPLASH_CON && glogger -s "Switch Console"
done

killall -9 $PROC_TO_KILL > /dev/null 2>&1

SVC_ALIVE="$(rc-status -a |grep " started "|cut -f 2 -d " " | tr "\n" " ")"
#SVC_ALIVE=$(ls /var/lib/init.d/started/[a-z]*|cut -f 6 -d "/"| tr "\n" " ")

# Now calculate startup sequence
glogger -s "Still running >$SVC_ALIVE<"

for i in $SVC_START_FIRST ; do
   if ( strstr " $SVC_BOOT $SVC_DEFAULT " " $i " ) ; then 
      SVC_START_SEQ="$SVC_START_SEQ $i"
   fi
done

for i in $SVC_BOOT $SVC_DEFAULT ; do
   if ( ! strstr " $SVC_START_SEQ $SVC_START_LAST $SVC_ALIVE " " $i " ) ; then 
      SVC_START_SEQ="$SVC_START_SEQ $i"
   fi
done
for i in $SVC_START_LAST ; do
   if ( ! strstr " $SVC_ALIVE $SVC_START_SEQ " " $i " ) ; then
      SVC_START_SEQ="$SVC_START_SEQ $i"
   fi
done

glogger -s "Services to start: <$SVC_START_SEQ>"

[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 2 $NUM_STEPS


#sleep 3
#/_config/bin/dvbmod unload > /dev/null 2>&1

[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 1 $NUM_STEPS

/_config/bin/cleanup.sh

MODS_TO_LOAD=" "

for j in {1..10} ; do
   MODS_LOADED="$(lsmod |cut -f 1 -d " " |grep -v "Module")"
   DONE=0
   for i in $MODS_LOADED ; do
      if ( strstr " $MOD_UNLOAD " " $i " ) ; then
         glogger -s "Unloading $i"
         modprobe -r $i
         DONE=1
         if ( ! strstr " $MODS_TO_LOAD " " $i " ) ; then
            MODS_TO_LOAD="${MODS_TO_LOAD}$i "
         fi
      fi
   done
   [ "$DONE" = "0" ] && break
   sleep 2
done

# Cleanup !
rm /tmp/.* > /dev/null 2>&1

[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 0 $NUM_STEPS
NUM_STEPS=$(($(echo "$SVC_START_FIRST" | wc -w) + 3 ))

lsmod |logger
ps x |logger
[ "$BOOT_SPLASH" == "1" ] && g2v_splash_exit
if [ "$AFP_WATCHDOG" != "" -a "$AFP_WATCHDOG" != "0" ] ; then
   afp-tool -h $((AFP_WATCHDOG + 3))
fi

glogger -s "Hibernating $SHUTDOWN_METHOD ..."
if [ "${SHUTDOWN_METHOD}" = "STR" ] ; then
   echo mem > /sys/power/state
elif [ "${SHUTDOWN_METHOD}" = "STD1" ] ; then   
   echo shutdown > /sys/power/disk
   echo disk > /sys/power/state
else
   echo platform > /sys/power/disk
   echo disk > /sys/power/state
fi

afp-tool -h 0
afp-tool -a 0 -t "Gen2VDR startet|..."
glogger -s "Wieder da ..."
[ "$BOOT_SPLASH" == "1" ] && g2v_splash_start "bootup"
[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 1 $NUM_STEPS
[ "$BOOT_SPLASH" == "1" ] && SPLASH_CON=$(fgconsole)
/etc/init.d/modules zap
/etc/init.d/modules start

for i in $MODS_TO_LOAD ; do
   glogger -s "Loading $i"
   modprobe $i
done
[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 2 $NUM_STEPS
#/_config/bin/dvbmod load

[ "$BOOT_SPLASH" == "1" ] && g2v_splash_prog 3 $NUM_STEPS

IDX=4
echo "Starting >$SVC_START_SEQ<"
DONE=""
for i in $SVC_START_SEQ ; do
    if [ "$DONE" = "" ] ; then
       if ( ! strstr " $SVC_START_FIRST " " $i " ) ; then
          DONE=1
          glogger -s "Waiting before Starting <$i>"
          sleep 15
       else
          [ "$BOOT_SPLASH" == "1" ] && [ "$CON" != "$SPLASH_CON" ] && killall -9 chvt && chvt $SPLASH_CON && glogger -s "Switch Console"
       fi
    fi
    glogger -s "Starting $i"
    /etc/init.d/$i start
#    g2v_splash_prog $IDX $NUM_STEPS
    IDX=$((IDX + 1))
done
[ "$BOOT_SPLASH" == "1" ] && g2v_splash_exit
[ "$(fgconsole)" = "16" ] && chvt 1
trap - HUP INT QUIT TERM ABRT ALRM EXIT
