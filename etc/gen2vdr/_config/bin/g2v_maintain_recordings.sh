#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
LOG="/log/maintain_recs.log"
NICE_VAL=${NOAD_NICE:-10}
#set -x
function execute() {
   log "Starte <$@>"
   nice -n $NICE_VAL "$@" 2>&1 | tee -a $LOG
   rc=${PIPESTATUS[0]}
   log "Exit <rc:$rc><$@>"
}

function log() {
   glogger -s "$*"
   echo "$(date +"%D %T") - $*" >> $LOG
}

if [ "$(pidof -o %PPID -x $0)" != "" ] ; then
   glogger -s "$0 is already running"
   exit
fi

[ "${VIDEO: -1}" != "/" ] && VIDEO="${VIDEO}/"

if [ "$USE_CUTTING_DIR" = "1" ] ; then
   TARGET_DIR="${VIDEO}_CUT_/"
   [ ! -e $TARGET_DIR ] && mkdir $TARGET_DIR
else
   TARGET_DIR="${VIDEO}"
fi

TFS=$(df $TARGET_DIR |tail -n 1| cut -f 1 -d " ")
SFS=$(df $VIDEO |tail -n 1| cut -f 1 -d " ")

# Delete empty directories
find $VIDEO -follow -type d -name "*" 2>/dev/null | while read i; do
   rmdir -p --ignore-fail-on-non-empty $i 2>/dev/null
done

# Start noad or cutting for all recordings
find $VIDEO -follow -type d -name "*.rec" 2>/dev/null | while read i; do
   if [ "$(readlink "$i")" != "" ] ; then
      echo "Ignoring link <$i>"
      continue
   fi
   if [ "$(df "$i")" != "$(df $VIDEO)" ] ; then
      echo "Ignoring other device <$i>"
      continue
   fi
   touch ${VIDEO}.update
   VID_FN=${i%.rec*}
   VID_RECDATE=${VID_FN##*/}
   VID_FN=${VID_FN%/*}
   VID_BASE="${VID_FN%/*}/"
   VID_FN=${VID_FN##*/}
   if [ "${VID_FN:0:1}" = "%" -o -d "${VID_BASE}%$VID_FN" ] ; then
      echo "Ignoring $i (already cutted)"
   elif [ "$MAINTAIN_NOAD" = "1" ] && [ ! -f "$i/marks" ] ; then
      # check for actual recording
      ls -l $i/ > /tmp/~noad1
      sleep 5
      ls -l $i/ > /tmp/~noad2
      if [ "$(diff -uN /tmp/~noad1 /tmp/~noad2)" = "" ] ; then
         log "Starting noad for <$i>"
         execute /_config/bin/g2v_noad.sh - "$i"
         touch "$i/marks"
         cp -a "$i/marks" "$i/marks_noad"
      fi
   elif [ "$MAINTAIN_CUTTING" = "1" ] && [ -s "$i/marks" ] ; then
      TARGET="${TARGET_DIR}${VID_BASE#$VIDEO}%${VID_FN}/${VID_RECDATE}.rec"
      if [ -f "$i/marks_noad" -a "$i/marks" -nt "$i/marks_noad" ] ; then
         # Check Disk free
         if [ "$TFS" != "$SFS" ] ; then
            ds=$(du -s -B 1000 "$i" |tr "\t" " "| cut -f 1 -d " ")
            tf=$(df -B 1000 $TARGET_DIR |tail -n 1|tr "\t" " "| tr -s " " | cut -f 4 -d " ")
            if [ $ds -ge $tf ] ; then
               log "Not cutting $i <$ds kB needed-$tf kB free>"
               continue
            fi
         fi
         log "Cutting $i to <$TARGET>"
         mkdir -p "${TARGET_DIR}${VID_BASE#$VIDEO}%${VID_FN}"
         ln -s "${TARGET_DIR}${VID_BASE#$VIDEO}%${VID_FN}" "${VID_BASE}"
         execute vdr --edit "$i"
         cp -a "$i/marks" "$i/marks_noad"
      fi
   fi
done
touch ${VIDEO}.update
