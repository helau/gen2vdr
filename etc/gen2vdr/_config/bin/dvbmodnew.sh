#!/bin/bash
source /_config/bin/g2v_funcs.sh
if [ "$(pidof -x "$0" -o $$ -o $PPID -o %PPID)" != "" ] ; then
   glogger -s "$0 is already running"
   exit 1
fi

MOD_AUTO="/etc/conf.d/modules"
DVBMOD_DEP="/_config/bin/dvbmod.dep"
DVBMOD_LOAD="/_config/bin/dvbmod.load"
DVBMOD_DEFAULT="/_config/bin/dvbmod.load.default"
ALL_DVB_MOD="/tmp/~alldvb"


make_dep() {
   [ -f $DVBMOD_DEP ] && rm $DVBMOD_DEP
   ALLDVB=""

   for i in $(cat /lib/modules/$(uname -r)/modules.pcimap |cut -f 1 -d " "|sort -u) ; do
      [ "$(grep "/$i.ko" $ALL_DVB_MOD)" != "" ] && ALLDVB="$ALLDVB $i"
   done

#   cd /usr/local/src/DVB/v4l
#   rm /tmp/~alldep 2>/dev/null
   for i in $(cat $ALL_DVB_MOD) ; do
      echo "$i ,$(modinfo $i | grep depends | cut -f 2- -d ":" | tr -d " ")," >> /tmp/~alldep
   done

   for i in $ALLDVB ; do
   #   echo $i
      MM=$(grep ",$i," /tmp/~alldep | cut -f 1 -d "." | tr "\n" " ")
      if [ "$MM" != "" ] ; then
         echo "$i $MM" >> $DVBMOD_DEP
      fi
   done
}


unload() {
   # delete dvb modules from /etc/modules.autoload.d/kernel-2.6
   [ "$(lsmod |grep "^dvb_bt8xx")" != "" ] && modprobe -r dvb_bt8xx > /dev/null 2>&1
   [ "$(lsmod |grep "^dst")" != "" ] &&  rmmod -f dst > /dev/null 2>&1

   for i in $(cat $DVBMOD_LOAD 2>/dev/null) ; do
      #echo "Unloading $i"
      modprobe -r $i
   done
   find /lib/modules/$(uname -r)/kernel/drivers/media -name "*.ko"| sed -e "s:.*/::" -e "s:.ko$::" | tr "-" "_" > $ALL_DVB_MOD
   for i in $(lsmod | cut -f 1 -d " ") ; do
      if [ "$(grep "^$i\$" $ALL_DVB_MOD)" != "" ] ; then
         glogger -s "DVB: Unloading <$i>"
         modprobe -r $i
      fi
   done
}

load() {
   # clean autoload
   [ ! -f $DVBMOD_LOAD ] && check
   for i in $(cat $DVBMOD_LOAD 2>/dev/null) ; do
       if [ "$i" = "dvb-ttpci" -a "$VIDEO_OUT" = "SVIDEO" ] ; then
          PARM="vidmode=2"
       else
          PARM=""
       fi	  
       modprobe $i $PARM
   done
}

check() {
   find /lib/modules/$(uname -r)/v4l-dvb -name "*.ko"| sed -e "s:.*/::" -e "s:.ko$::" | tr "-" "_" > $ALL_DVB_MOD
   make_dep

   MODULES=$(sh /_config/bin/detect_modules.sh 2>/dev/null |sort -u)
   if [ -s $DVBMOD_DEFAULT ] ; then
      DVBMOD=$(cat $DVBMOD_DEFAULT)
   else
      DVBMOD=""
   fi
   for i in ${MODULES//-/_} ; do
      if [ "$(grep "^$i\$" $ALL_DVB_MOD)" != "" ]   ; then
         MM=$(grep "^$i " $DVBMOD_DEP 2>/dev/null| cut -f 2- -d " ")
         if [ "$MM" != "" ] ; then
            DVBMOD="$DVBMOD $MM"
         else
            DVBMOD="$DVBMOD $i"
         fi
      fi
   done

   [ -f $DVBMOD_LOAD ] && rm $DVBMOD_LOAD
   [ -f $DVBMOD_LOAD.budget ] && rm $DVBMOD_LOAD.budget
   for i in $(echo $DVBMOD | tr " " "\n" | sort -u) ; do
       echo "DVB module: $i"
       if [ "$i" = "dvb-ttpci" ] ; then
          echo "$i" >> $DVBMOD_LOAD
       else
          echo "$i" >> $DVBMOD_LOAD.budget
       fi
   done
   [ -f $DVBMOD_LOAD.budget ] && cat $DVBMOD_LOAD.budget >> $DVBMOD_LOAD
   [ -f $DVBMOD_LOAD ] && cat $DVBMOD_LOAD | while read i ; do
       /_config/bin/module-update.sh add $i
   done
   [ -e $DVBMOD_LOAD ] && sed -i $DVBMOD_LOAD -e "s/\-/_/g"
   source $MOD_AUTO
   for i in ${modules//-/_} ; do
      if [ "$(grep "^$i\$" $ALL_DVB_MOD)" != "" ] && [ "$(grep "^$i\$" $DVBMOD_LOAD)" = "" ] ; then
         /_config/bin/module-update.sh del $i
      fi
   done
}

DVBTMP="/tmp/.dvb"

if [ "$1" = "load" ] ; then
   DIFF=999999
   if [ -f $DVBTMP ] ; then
      FDATE=$(ls -l --time-style=+%s $DVBTMP | tr -s ' ' |cut -f6 -d ' ')
      if [ "$FDATE" != "" ] ; then
         ACTDATE=$(date +%s)
         DIFF=$(($ACTDATE - $FDATE))
      fi
   fi
   if [ $DIFF -le 10 ] && [ $DIFF -ge 1 ] ; then
      echo "waiting before reloading driver"
      sleep $((10 - $DIFF))
   fi
   load
elif [ "$1" = "unload" ] ; then
   unload
elif [ "$1" = "reload" ] ; then
   unload
   sleep 10
   load
elif [ "$1" = "check" ] ; then
   rm $DVBMOD_DEP 2>/dev/null
   check
else
   echo "Syntax: $0 <load|unload|reload|check>"
fi

touch $DVBTMP
