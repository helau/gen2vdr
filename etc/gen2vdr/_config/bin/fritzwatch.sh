#!/bin/bash
source /_config/bin/g2v_funcs.sh
#echo $0
LASTCALL=""
#MSN=";123456;|;123457;"
MSN=";"
CALL_DB="/root/caller.db"
CALL_LOG="/log/fritz.log"

sleep 1

if [ "$1" = "-stop" ] ; then
   pids_to_kill=$(pidof -x "$0" nc6 -o $$ -o $PPID -o %PPID)
   [ "$pids_to_kill" != "" ] && kill -9 $pids_to_kill   
   #killall -9 nc6 >/dev/null 2>&1
   exit
elif [ "$1" = "-start" ] ; then
   glogger -s "Starting $0"
elif [ "$(pidof nc6)" = "" -a "$1" != "-restart" ] ; then
   if [ "$(which nc6)" = "" ] ; then
      glogger -s "nc6 nicht vorhanden"
      exit
   fi
   ping -b -c1 fritz.box > /dev/null 2>&1
   if [ "$?" != "0" ] ; then
      glogger -s "FritzBox nicht erreichbar"
      for i in $(seq 1 30) ; do
         ping -b -c1 fritz.box > /dev/null 2>&1
         if [ "$?" = "0" ] ; then
            break
         fi
         sleep 10
      done
   else
      if [ "$1" = "-restart" ] ; then
         svdrps MESG "FritzBox Anrufmonitor nicht erreichbar"
         sleep 5
         svdrps MESG "Aktivieren mit #96*5*"
      fi
   fi
   glogger -s "Restarting <$0>"
   sleep 300
else
   while [ "$(pidof nc6)" != "" ] ; do
      read LINE
      INCOMING=$(echo "$LINE" | grep ";RING;" | grep -E "$MSN")
      CALLER=""
      if [ "$INCOMING" != "" ] &&  [ "$INCOMING" != "$LASTCALL" ] ; then
         LASTCALL=$INCOMING
         NUMBER=$(echo "$INCOMING" | cut -f 4 -d ";")
         CMSN=$(echo "$INCOMING" | cut -f 5 -d ";")
         if [ "$NUMBER" != "" ] ; then
            CALLER=$(grep "^$NUMBER " $CALL_DB | cut -f 2- -d " ")
            if [ "$CALLER" = "" ] ; then
               sed -i $CALL_DB -e "/$NUMBER .*/d"
               svdrps "MESG $NUMBER ruft $CMSN"
               wget -O - "http://www2.dasoertliche.de/?id=3339GS10886550222242399&la=de&form_name=detail&lastFormName=search_inv&ph=$NUMBER&recFrom=1&hitno=99&kgs=11000000&zvo_ok=1&page=TREFFERLISTE&context=TREFFERLISTE&action=TEILNEHMER&orderby=name&ttforderby=rel&la=de&detvert_ok=1" >/tmp/tst.out
               CALLNAME=$(grep "detail_top" /tmp/tst.out | cut -f 2 -d ">" | sed -e "s/<\/a>/, /" -e "s/<.*//" -e "s/[ ]*$//g" -e "s/\&nbsp;/ /g")
               if [ "$CALLNAME" != "" ] ; then
                  ADDRESS=$(grep -A 10 "adresse start" /tmp/tst.out |grep "<div>"| cut -f 2,3 -d ">"| sed -e "s/<.*>/, /" -e "s/<.*//" -e "s/\&nbsp;/ /g")
                  CALLER="$CALLNAME, $ADDRESS"
                  echo "$NUMBER $CALLER" >> $CALL_DB
               fi
            fi
            if [ "$CALLER" != "" ]; then
               svdrps "MESG $NUMBER $CALLER"
            fi
         else
            svdrps "MESG Anruf an $CMSN"
         fi
         glogger -s "Caller: <$NUMBER> $CALLER"
      fi
      if [ "$CALL_LOG" != "" ] ; then
         echo "$LINE;  $CALLER" >> $CALL_LOG
      fi
      sleep 1
   done
   sleep 300
fi

screen -dm sh -c "sleep 3; kill -9 $(pidof -x nc6 $0); nc6 fritz.box 1012 | $0 -restart"
