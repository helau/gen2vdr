#!/bin/bash
source /_config/bin/g2v_funcs.sh
trap "" HUP INT QUIT TERM ABRT ALRM EXIT KILL STOP
#set -x
[[ -f "${0}.conf" ]] && source "${0}.conf"

# processes which are stopping a shutdown
PROC_STOP_SHUTDOWN="$PROC_STOP_SHUTDOWN make gcc cc1 mencoder replex yac_exec.sh lame vdrsync.pl vdrburn.sh g2v_init.sh g2v_epgscan.sh"

NVRAMCMD="/usr/bin/nvram-wakeup"
SETTIMERCMD="/_config/bin/set_timer.sh"
NVRAMCFG="/_config/install/nvram-wakeup.conf"
#PROC_ALARM="/proc/acpi/alarm"
PROC_ALARM="/sys/class/rtc/rtc0/wakealarm"
# Minimaler Abstand zu naechsten Timer in Minuten
WAKEUP_DIFF_MINIMUM=15
NEXT_TIMER="$1"
CLOCK="$(source /etc/conf.d/hwclock; echo ${clock})"
DISABLE_STR=0
USE_POWEROFF_KERNEL=0

NT=""

err_exit() {
   if [[ ! -f "$VDR_FORCE_SHUTDOWN" ]] ; then
      glogger -s "Shutdown abgebrochen <$*>"
      svdrps MESG "Shutdown abgebrochen"
      svdrps MESG "$*"
      exit
   else
      glogger -s "Shutdown trotz <$*>"
   fi
}

set_clock() {
   /etc/init.d/hwclock save
#   /etc/init.d/hwclock stop
}

set_nvram_wakeup() {
   glogger -s "Next nvram alarm at: $(date -d "1970-01-01 UTC $1 seconds" +"%Y-%m-%d %R")"
   echo "Using nvram wakeup"
   if [[ ! -e /dev/rtc && "$DIRECTISA" = "0" ]] ; then
      modprobe rtc
      for i in {1..5} ; do
         [[ -e /dev/rtc ]] && break
         sleep 1
      done
   fi

   if [[ -n "$NVRAM_BOARD" ]] ;then
      if [[ -f "$NVRAMCFG.$NVRAM_BOARD" ]] ; then
         NVRAMCMD="$NVRAMCMD -C $NVRAMCFG.$NVRAM_BOARD"
      else
         NVRAMCMD="$NVRAMCMD -I $NVRAM_BOARD"
      fi
   else
      [[ -f "$NVRAMCFG" ]] && NVRAMCMD="$NVRAMCMD -C $NVRAMCFG"
   fi
   [[ "$DIRECTISA" = "1" ]] && NVRAMCMD="$NVRAMCMD --directisa"

   glogger -s "$NVRAMCMD -ls $1"
   $NVRAMCMD -ls "$1"
   rc=$?
   [[ $rc -eq 1 ]] && USE_POWEROFF_KERNEL=1
   [[ $rc -eq 2 ]] && err_exit "nvram-wakeup fehlgeschlagen"
}

set_acpi_timer() {
   echo 0 > "$PROC_ALARM"
   sleep 1
   if [[ -f "$PROC_ALARM" && "$1" -gt 0 ]] ; then
      # check if NEXT_TIMER is within next 24 hours
      WAKEUP="$(date -d "1 day" +%s)"
      if [[ $1 -lt $WAKEUP || "${WAKEUP_METHOD}" = "ACPI_NOLIMIT" ]] ; then
         WAKEUP="$1"
      else
         NEXT_TIMER="$WAKEUP"
      fi
      if [[ "$CLOCK" = "UTC" ]] ; then
         dp="-u"
      else
         dp=""
      fi
      #NEXT_ALARM=$(date $dp -d "1970-01-01 UTC $WAKEUP seconds" +"%Y-%m-%d %T")
      NEXT_ALARM="$(date $dp -d "1970-01-01 UTC $WAKEUP seconds" +"%s")"
      echo "$NEXT_ALARM" > "$PROC_ALARM"
      sleep 1
      glogger -s "Next acpi alarm at: $NEXT_ALARM"
      cat /proc/driver/rtc |logger -s
   else
      [[ $1 -gt 0 ]] && err_exit "ACPI wakeup nicht möglich"
   fi
}

glogger -s "$0 -$1-"
[[ -f "$WAKEUP_FILE" ]] && rm -f "$WAKEUP_FILE"

# check for forced Shutdown
[[ -f /tmp/sandboxpids.tmp ]] && err_exit "emerge läuft"
# check if there are some users logged in
if [[ "$IGNORE_CONNECTION" = "0" ]] ; then
   CONNECTIONS="$(netstat -t |grep "^tcp"|grep -v "localhost:"|wc -l)"
   [[ "$CONNECTIONS" != "0" ]] && err_exit "Verbindungen sind aktiv"
fi
for x in ${PROC_STOP_SHUTDOWN} ; do
   [[ -n "$(pidof -x "$x")" ]] && err_exit "$x läuft"
done

ACT_DATE="$(date +%s)"

# Nächsten Timer prüfen
if [[ $1 -gt $WAKEUP_RESERVE ]] ; then
   NEXT_TIMER="$(($1 - $WAKEUP_RESERVE))"
   WAKEUP_DIFF="$((($NEXT_TIMER - $ACT_DATE) / 60))"
   [[ $WAKEUP_DIFF -lt $WAKEUP_DIFF_MINIMUM ]] && err_exit "Nächster Timer in $WAKEUP_DIFF Minuten"
else
   NEXT_TIMER=0
fi

# Ist täglicher Wakeup aktiviert
if [[ -n "$WAKEUP_DURATION" && $WAKEUP_DURATION -gt 0 ]] ; then
   ACT_HOUR="$(date +%k)"
   if [[ $WAKEUP_HOUR -gt $ACT_HOUR ]] ; then
      NEXT_WAKEUP="$(date -d "$WAKEUP_HOUR:00" +"%s")"
   else
      NEXT_WAKEUP="$(date -d "$WAKEUP_HOUR:00 1 day" +"%s")"
   fi
   NEXT_WAKEUP="$(($NEXT_WAKEUP - $WAKEUP_RESERVE))"
   WAKEUP_DIFF="$((($NEXT_WAKEUP - $ACT_DATE) / 60))"
   [[ $WAKEUP_DIFF -lt $WAKEUP_DIFF_MINIMUM ]] && err_exit "Täglicher Wakeup in $WAKEUP_DIFF Minuten"
   if [[ "$NEXT_TIMER" = "0" || $NEXT_TIMER -gt $NEXT_WAKEUP ]] ; then
      NEXT_TIMER="$NEXT_WAKEUP"
      [[ -n "$STR_WU_LIMIT" && $(($WAKEUP_DIFF / 60)) -lt $STR_WU_LIMIT ]] && DISABLE_STR=1
   fi
fi

svdrps MESG "System wird heruntergefahren"
# Uhrzeit setzen
set_clock

if [[ "$WAKEUP_METHOD" = "NVRAM" ]] ; then
   set_nvram_wakeup "$NEXT_TIMER"
elif [[ "$WAKEUP_METHOD" = "SET_TIMER" ]] ; then
   $SETTIMERCMD "$NEXT_TIMER" "$(($NEXT_TIMER - $ACT_DATE))"
elif [[ "${WAKEUP_METHOD:0:4}" = "ACPI" ]] ; then
   set_acpi_timer "$NEXT_TIMER"
elif [[ "$WAKEUP_METHOD" = "WAKEUP_BOARD" ]] ; then
   /_config/bin/set_wakeupboard_timer.sh "$NEXT_TIMER"
else
   glogger -s "No wakeup possible - shutting down anyway"
fi

# Check for FilesystemCheck
DOCHECK="0"
if [[ "$FSCK_WEEK" != "0" ]] ; then
   LCHKF="/etc/lastCheck"
   if [[ -n "$LCHKF" && -f "$LCHKF" ]] ; then
      LCHECKED="$(ls --full-time $LCHKF | cut -f 6,7 -d " ")"
      lWeek="$(date -d "$LCHECKED" +"%Y%W")"
      actWeek="$(date +"%Y%W")"
      if [[ $(($actWeek-$lWeek)) -ge $FSCK_WEEK ]] ; then
         DOCHECK="1"
      fi
   else
      DOCHECK="1"
   fi
   [[ "$DOCHECK" = "1" ]] && touch "$LCHKF" /forcefsck
fi

# if SUSPEND To RAM is set and last manual Startup is too long ago then halt
if [[ "${SHUTDOWN_METHOD:0:2}" = "ST" && -n "$STR_MAN_LIMIT" && $STR_MAN_LIMIT -gt 0 ]] ; then
   if [[ -f "$MANSTART_FILE" ]] ; then
      LMS="$(ls --full-time $MANSTART_FILE | cut -f 6,7 -d " ")"
      lDay="$(date -d "$LMS" +%-j)"
      aDay="$(date +%-j)"
      if [[ $aDay -lt $lDay ]] ; then
         dDiff="$(($aDay + 365 - $lDay))"
      else
         dDiff="$(($aDay - $lDay))"
      fi
      [[ $dDiff -gt $STR_MAN_LIMIT ]] && DISABLE_STR=1
   fi
fi

if [[ $1 != 0 ]] ; then
   NT="$(date -d "1970-01-01 UTC $NEXT_TIMER seconds" +"%Y%m%d%H%M")"
   touch -t "$NT" "$WAKEUP_FILE"
fi

STOP_VDR=1

if [[ "$SHUTDOWN_METHOD" = "PowerOffKernel" ]] || [[ "$SHUTDOWN_METHOD" = "PowerOffNVRAM" && "$USE_POWEROFF_KERNEL" = "1" ]] ; then
   BOOT_DISK="$(df /boot|grep "^/dev" | cut -b 1-8)"
   if [[ -n "$(dd if=${BOOT_DISK} bs=512 count=1  2>/dev/null |grep -i GRUB 2>/dev/null )" ]] ; then
      REBOOT_LINE="$(grep -s ^title "$GRUBCNF" | grep -i -n poweroff | { IFS=: read a b ; echo $a ; })"
      grub-set-default "$((REBOOT_LINE-1))"
   else
      lilo -R poweroff
   fi
   SHUTDOWN_CMD="shutdown -r now"
elif [[ "${SHUTDOWN_METHOD:0:2}" = "ST" && "$DOCHECK" = "0" && "$DISABLE_STR" = "0" ]] ; then
   SHUTDOWN_CMD="/_config/bin/hibernate.sh"
   STOP_VDR=0
elif [[ "$SHUTDOWN_METHOD" = "Shutdown" ]] ; then
   SHUTDOWN_CMD="shutdown -h now"
else
   SHUTDOWN_CMD="halt"
fi
svdrps MESG "System wird heruntergefahren"
glogger -s "Shutting down: <$SHUTDOWN_CMD>"
/_config/bin/activy_lcdtimer.sh
[[ "$DOCHECK" = "1" ]] && svdrps MESG "Dateisystemprüfung beim nächsten Start" && sleep 5
touch /tmp/.shutdown
rm -f "$STOPVDR_FILE"

if [[ "$STOP_VDR" = "1" ]] ; then
   /etc/init.d/vdr stop
   /etc/init.d/local stop
fi
$SHUTDOWN_CMD
