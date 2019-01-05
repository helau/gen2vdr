#!/bin/bash
BATCH_FILE="/tmp/create-new"
if [ ! -s $BATCH_FILE ] ; then
   mp3c -i /_config/bin/.mp3crc -b $BATCH_FILE > /dev/null 2>&1
fi   
if [ -s $BATCH_FILE ] ; then
   CD_SONGS=`cat $BATCH_FILE | grep "/cdda2wav" |grep "/lame" | sed 's/.*--tt//' | cut -f 2 -d "\""`
   CD_TRACKS=`cat $BATCH_FILE | grep cdda2wav | grep -c "\-\-tn"`

   CD_INFO=`cat $BATCH_FILE | grep -m 1 "^mkdir" | sed 's/.*audio//'`
   CD_ARTIST=`echo $CD_INFO | cut -f 2 -d "/"`
   CD_TITLE=`echo $CD_INFO | cut -f 3 -d "/" | cut -f 2 -d "_"`
   CD_YEAR=`echo $CD_INFO | cut -f 3 -d "/" | cut -f 1 -d "_"`
   echo "$CD_ARTIST"
   echo "$CD_TITLE ($CD_YEAR)"
   echo ""

   cat $BATCH_FILE | grep "/cdda2wav" |grep "/lame" | sed 's/.*--tt//' | cut -f 2 -d "\""
#  NUM=1
#  for i in $CD_SONGS ; do
#     echo "$NUM ${i}"
#     NUM=$(($NUM+1))
#  done
fi
