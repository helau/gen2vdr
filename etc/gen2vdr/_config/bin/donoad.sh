#!/bin/bash
# Wait for other noads to end "
for i in $(seq 1 60) ; do
   if [ "$(pidof noad)" = "" ] ; then
      break
   fi
   sleep 60
done
killall -9 noad

NOAD_OPTS="--comments --jumplogo --ac3 --overlap --backupmarks --statisticfile=/var/log/noadstat -vvv"

nice -n 10 noad $NOAD_OPTS - "$1"
touch "$1/marks"
cp -a "$1/marks" "$i/marks_noad"
