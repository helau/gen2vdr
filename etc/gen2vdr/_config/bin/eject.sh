#!/bin/bash
source /_config/bin/g2v_funcs.sh
# Skript which is executed when the powerbutton is pressed

EJECT_CMD="eject /dev/cdrom"
CLOSE_CMD="eject -t /dev/cdrom"

EJTMP="/tmp/~ej"

ACTDATE=`date +%s`
if [ -f $EJTMP ] ; then
   FDATE=`ls -l --time-style=+%s $EJTMP | tr -s ' ' |cut -f6 -d ' '`
   DIFF=$(($ACTDATE - $FDATE))
else
   DIFF=999999
fi
discinfo /dev/cdrom >/dev/null 2>&1
RC=$?
if [ "$RC" = "0" ] | [ $DIFF -le 180 ] ; then
   glogger -s "CLOSE_CD sent"
   $CLOSE_CMD
   rm $EJTMP
else
   glogger -s "EJECT_CD sent"
   umount /media/dvd > /dev/null 2>&1
   umount /mnt/cdfs > /dev/null 2>&1
   $EJECT_CMD
   touch $EJTMP
fi
