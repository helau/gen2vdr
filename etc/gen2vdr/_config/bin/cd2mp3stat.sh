#!/bin/bash
CD_INFO="/tmp/audio_cd"

/_config/bin/cda_info.sh > $CD_INFO
LAME_TRNUM=`ps x |grep "/lame " | grep "preset" | sed 's/.*--tn/t/' | cut -f 2 -d " "`
if [ "$LAME_TRNUM" = "" ] ; then
   CDDA_TRNUM=`ps x |grep "/cdda2wav " | grep "D<" | sed 's/.*-t/t/' | cut -f 2 -d " "`
   if [ "$CDDA_TRNUM" != "" ] ; then
      echo "Titel $CDDA_TRNUM wird gelesen"
      echo ""
   fi
else
   echo "Titel $LAME_TRNUM wird umgewandelt"
   echo ""
fi
if [ -s $CD_INFO ] ; then
   echo ""
   cat $CD_INFO
fi
