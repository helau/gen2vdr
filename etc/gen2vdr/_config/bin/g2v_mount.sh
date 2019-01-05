#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x 
PARMS="$@"
glogger -s "$0 $PARMS"
err_msg=$(eval halevt-mount "$@" 2>&1)
if [ "${err_msg//umask=002/}" != "$err_msg" ] ; then
   PARMS="${PARMS//-m 002/}"
   glogger -s "$0 $PARMS"
   err_msg=$(eval halevt-mount $PARMS 2>&1)
fi
if [ "$1" = "-u" ] ; then
   sleep 5
   MP=$(halevt-mount -l |grep "^$2:"| cut -f 3 -d ":")
   if [ "$MP" != "" ] && [ -d "$MP" ] ; then
      [ -d "${MP%/}/video" ] && MP="${MP%/}/video"
      /_config/bin/linkvid.sh "$MP"
   else
      DEV=$(halevt-mount -l |grep "^$2:"| cut -f 2 -d ":")
      for i in $(grep "^/dev.*noauto.*" /etc/fstab | tr " " "\t"| cut -f 1) ; do
         LNK="$(readlink "$i")"
         if [ "/dev/$LNK" = "$DEV" ] ; then
            mount $i
            sh /_config/bin/disc_speed.sh -c $DEV
         fi
      done
   fi
fi
