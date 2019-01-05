#!/bin/bash
source /_config/bin/g2v_funcs.sh
MIN_DISK_FREE=20
MIN_SLEEP=10
MAX_SLEEP=600

MPIDS=$(pidof -x "$0" -o $$ -o $PPID -o %PPID)
if [ "$MPIDS" != "" ] ; then
    glogger -s "Killing $0 $MPIDS"
    kill -9 $MPIDS
fi

#set -x

DEL_TIMERS=""

check_df() {
   disk_free="$(df /mnt/data | tail -n 1 | tr "\t" " " | tr -s " ")"
   dfr="${disk_free#* }"
   KB_TOTAL="${dfr%% *}"
   dfr="${dfr#* }"
   KB_USED="${dfr%% *}"
   KB_FREE="$(($KB_TOTAL - $KB_USED))"
}

TEMP_FILE="/.diskfree"

[ "$MIN_DISK_FREE" = "0" ] && exit
[ -f $TEMP_FILE ] && rm -f $TEMP_FILE

MIN_FREE=$(($MIN_DISK_FREE * 1024))
WARN_FREE=$(($WARN_DISK_FREE * 1024))

TEMP_FILE_SIZE=0

while [ 1 ] ; do
   check_df
   DO_DEL=0
   SLEEP_SECS=10
   if [ $KB_FREE -le $MIN_FREE ] ; then   
      [ -f $TEMP_FILE && rm -f $TEMP_FILE
      # Check for yacoto
      yac_pids=$(ps x | grep " /etc/vdr/plugins/yacoto/" | grep -v grep | cut -b 1-5)
      if [ "$yac_pids" != "" ] ; then
         svdrps MESG "Video-Platte ist voll - Yacoto wird beendet"
         kill -9 $yac_pids
         rm -rf /tmp/YAC_*
         sleep 10
         continue
      fi

      svdrpsend.sh LSTT | grep "^250.* 1:" | while read i ; do
         timer_deact=1
         glogger -s "Timer <$i> wird deaktiviert"
         tim=${i#* 1:}
         svdrps UPDT "0:${tim}"
         DEL_TIMERS="${DEL_TIMERS}${tim}||"
      done
      [ "$timer_deact" = "1" ] && svdrps MESG "Video-Platte ist voll - Timer wurden deaktiviert"

      # Check for yacoto
      DO_DEL=1
   elif [ $KB_FREE -lt $WARN_FREE ] ; then
      svdrps MESG "Video-Platte ist bald voll - Aufnahmen loeschen"    
      DO_DEL=1
      SLEEP_SECS=10
   else
      SLEEP_SECS=$(($KB_FREE / 20000))
      if [ $TEMP_FILE_SIZE -lt $MIN_FREE ] ; then 
         # create a tempfile which could be freed in emergency case
         NUM_BLOCKS=0
         if [ $KB_FREE -gt $(($MIN_FREE * 2)) ] ; then
            NUM_BLOCKS=$MIN_FREE
         elif [ $KB_FREE -gt $MIN_FREE ] ; then
            NUM_BLOCKS=$(($KB_FREE - $MIN_FREE))
         fi
         dd if=/dev/zero of=$TEMP_FILE bs=1K count=$NUM_BLOCKS
         TEMP_FILE_SIZE=$NUM_BLOCKS
      fi
   fi

   if [ "$DEL_TIMERS" != "" ] && [ $KB_FREE -gt 100000 ] ; then
      while [ "$DEL_TIMERS" != "" ] ; do
         tim=${DEL_TIMERS%%||*}
         glogger -s "Timer <$tim> wird reaktiviert"
         svdrps UPDT "1:${tim}"
         DEL_TIMERS="${DEL_TIMERS#*||}"
      done
   fi

   if [ "$DO_DEL" = "1" ] ; then
      for i in $(find $VIDEO -follow -type d -name "*.del") ; do
         rm -rf $i
      done
   fi

   if [ $SLEEP_SECS -lt $MIN_SLEEP ] ; then
      SLEEP_SECS=$MIN_SLEEP
   elif [ $SLEEP_SECS -gt $MAX_SLEEP ] ; then
      SLEEP_SECS=$MAX_SLEEP
   fi

   sleep $SLEEP_SECS
done
[ -f $TEMP_FILE ] && rm -f $TEMP_FILE
