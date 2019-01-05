#!/bin/bash
source /_config/bin/g2v_funcs.sh

#set -x
if [ "$1" = "-vdr" -o "$1" = "1" ] ; then
   if [ "${PLUGINS/* lcdproc */}" = "" ] ; then
      svdrps PLUG lcdproc OFF
      svdrps PLUG lcdproc ON
   elif [ "${PLUGINS/* imonlcd */}" = "" ] ; then
      [ "${LCD/*imon*/}" = "" ] && /etc/init.d/LCDd stop 2>/dev/null
      sleep 2
      svdrps PLUG imonlcd ON
   elif [ "${PLUGINS/* alcd */}" = "" ] ; then
      [ "${LCD/*activy3*/}" = "" ] && /etc/init.d/LCDd stop 2>/dev/null
      sleep 2
      svdrps PLUG alcd UNLOCK
      [ "$BLOCKFILE" != "" ] && rm $BLOCKFILE 2>/dev/null
   elif [ "${PLUGINS/* dm140vfd */}" = "" ] ; then
      [ "${LCD/*dm140*/}" = "" ] && /etc/init.d/LCDd stop 2>/dev/null
      sleep 2
      svdrps PLUG dm140vfd on
      [ "$BLOCKFILE" != "" ] && rm $BLOCKFILE 2>/dev/null
   fi
else
   if [ "${PLUGINS/* lcdproc */}" = "" ] ; then
      svdrps PLUG lcdproc OFF
   elif [ "${PLUGINS/* imonlcd */}" = "" ] ; then
      svdrps PLUG imonlcd OFF
      [ "${LCD/*imon*/}" = "" ] && /etc/init.d/LCDd start 2>/dev/null
   elif [ "${PLUGINS/* alcd */}" = "" ] ; then
      svdrps PLUG alcd LOCK
      [ "${LCD/*activy3*/}" = "" ] && /etc/init.d/LCDd start 2>/dev/null
   elif [ "${PLUGINS/* dm140vfd */}" = "" ] ; then
      svdrps PLUG dm140vfd off
      [ "${LCD/*dm140*/}" = "" ] && /etc/init.d/LCDd start 2>/dev/null
   fi
fi
