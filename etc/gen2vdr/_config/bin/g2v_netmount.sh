#!/bin/bash
source /_config/bin/g2v_funcs.sh

RC=0

execCmd() {
   glogger -s "Exec <$1>"
   $1 2>&1 |glogger -s
   RC=${PIPESTATUS[0]}
   glogger -s "Exit <rc:$RC><$1>"
}

#set -x
SLEEP_SECS=30
MP_BASE=/mnt
KNOWN_FS=" nfs cifs "
LINK_DIRS=" video film audio pictures "

if [ "$(pidof -x "$0" -o $$ -o $PPID -o %PPID)" != "" ] ; then
   if [ "$1" == "-del" ] ; then
      #set -x
      kill $(pidof -x "$0" -o $$ -o $PPID -o %PPID)
   else
      glogger -s "$0 wurde bereits gestartet"
      exit 1
   fi
fi

INIT=1

while [ 1 ] ; do
   grep -v "^#" /etc/conf.d/g2vmount | tr "\t" " " | tr -s " " | while read i ; do
      FS=${i%% *}
      [ "$FS" == "" ] && continue
      if [ "${KNOWN_FS/* $FS */}" != "" ] ; then
         glogger -s "Unbekannter FSType <$FS>"
         exit
      fi
      i=${i#* }
      IP=${i%% *}
      [ "$IP" == "" ] && continue
      MAC=""
      if [ "${IP/*:*}" == "" ] ; then
         MAC=${IP#*:}
         IP=${IP%%:*}
      fi
      i=${i#* }
      MP=${i%% *}
      [ "$MP" == "" ] && continue
      i=${i#* }
      PARMS=${i%% *}
      if ( ping -c 1 -w 2 $IP >/dev/null 2>&1 ) && [ "$INIT" != "1" ] ; then
         MD=${MP_BASE%/}/${IP}_${MP#/}
         if [ "$(mount | grep " $MD ")" == "" ] ; then
#            set -x
            mkdir -p "$MD"
            if [ "$FS" == "nfs" ] ; then
               FMP="${IP}:/${MP#/}"
            else
               FMP="//${IP}/${MP#/}"
            fi
            execCmd "mount -t $FS $FMP $MD -o $PARMS"
            MP=${MP,,}
            if [ "$RC" == 0 ] ; then
               for j in $LINK_DIRS ; do
                  TL="/$j/_SRV_${IP}"
                  if [ -e $TL ] ; then
                     for k in 0 1 2 3 4 5 6 7 8 9 ; do
                        if [ ! -e  ] ; then
                           TL=${TL}_${k}
                           break
                        fi
                     done
                  fi
                  if [ "${MD/*$j*/}" == "" ] ; then
                     if [ "$j" == "video" ] ; then
                        /_config/bin/linkvid.sh "$MD"
                     else
                        ln -s "$MD" "$TL"
                     fi
                  elif [ -d ${MD}/${j} ] ; then
                     if [ "$i" == "video" ] ; then
                        /_config/bin/linkvid.sh "{MD}/${j}"
                     else
                        ln -s "${MD}/${j}" $TL
                     fi
                  fi
               done
               touch /video/.update
            fi
         fi
      else
         mount | grep " on /mnt/${IP}_" | while read j ; do
            MP="${j#* on }"
            /_config/bin/linkvid.sh -del "${MP%% *}"
            glogger -s "$IP ist nicht erreichbar - entferne <${j%% *}>"
            umount -fn "${j%% *}"
            touch /video/.update
         done
         for j in $LINK_DIRS ; do
            rm -f /${j}/_SRV_${IP}*
         done
         if [ "$MAC" != "" ] ; then
            execCmd "wakeonlan $MAC"
         fi
      fi
   done
   [ "$1" == "-del" ] && break
   if [ "$INIT" == "1" ] ; then
      INIT=0
   else
      sleep $SLEEP_SECS
   fi
done
