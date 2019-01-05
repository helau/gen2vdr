#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
XARGS_OPT="--null --no-run-if-empty"  # Optionen für "xargs" 
LOGFILE="/var/log/g2v_cleanup.log"    # Logdatei
MAXLOGSIZE=$((50*1024))               # Größe in Byte (50 kb)

[ ! -d /root/.screen ] && mkdir /root/.screen
find /log /root/.screen -follow -mtime +5 -type f ! -name "g2v_log_install*" \
     -print0 | xargs $XARGS_OPT rm -vf {} >> "$LOGFILE"

if [ -e "$LOGFILE" ] ; then           # Log-Datei umbenennen, wenn zu groß
  FILESIZE=$(stat -c %s $LOGFILE)
  [ $FILESIZE -gt $MAXLOGSIZE ] && mv -f "$LOGFILE" "${LOGFILE}.old"
fi
