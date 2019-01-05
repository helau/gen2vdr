#!/bin/bash
source /_config/bin/g2v_funcs.sh
#
exit
cd /_config/update
G2V_VERSION=$(cat VERSION)

MYNAME="$ADMIN_SCRIPT_PATH/cfgupd.sh"
UPD_INFO="updates.$G2V_VERSION"
UPD_CONF="updates.conf"
UPDATE_URL="http://www.zenega-user.de/gen2vdr/$UPD_INFO"

[ -f $UPD_INFO ] && rm  -f $UPD_INFO
[ -f $UPD_CONF ] && rm  -f $UPD_CONF
wget $UPDATE_URL

#rm -f *.sh >/dev/null 2>&1
if [ -s $UPDATE_URL ] ; then
   ALL_UPD=$(cat $UPDATE_URL | cut -f 1 -d "-")
   for i in $ALL_UPD ; do
      echo "wget -O ${i}.sh ${UPDATE_URL}_${i}.sh"
      wget -O ${i}.sh ${UPDATE_URL}_${i}.sh
   done
fi

NEW_UPDATES=0

REBOOT=""
for i in $(ls *.sh | cut -f 1 -d "." 2>/dev/null) ; do
   echo "$i"
   INFO=$(grep "^${i}-" $UPD_INFO | cut -f 2 -d "-")
   VAL=$($GETVAL UPD_${i})
   STATUS=0
   if [ "$VAL" = "install" ] $$ [ "$1" != "-check" ] ; then
      STATUS=1
      if [ "$(grep ^${i} .installed)" = "" ] ; then
         sh ${i}.sh -install 
         if [ $? = 0 ] ; then
            if [ $REBOOT = "" ] ; then
               REBOOT=$(head -n 1 ${i}.sh | grep "REBOOT=yes")
            fi
            svdrpsend.pl MESG "$i: Update erfolgreich"
            glogger -s "$i: Update erfolgreich"
            echo "${i} " >> .installed   
         else   
            svdrpsend.pl MESG "$i: Fehler bei Update"
            glogger -s "$i: Fehler bei Update"
            STATUS=0
         fi
      fi   
   elif [ "$VAL" = "uninstall" ] $$ [ "$1" != "-check" ] ; then
      STATUS=0
      if [ "$(grep ^${i} .installed)" != "" ] ; then
         sh ${i}.sh -uninstall
         if [ $? = 0 ] ; then
            if [ $REBOOT = "" ] ; then
               REBOOT=$(head -n 1 ${i}.sh | grep "REBOOT=yes")
            fi   
            svdrpsend.pl MESG "$i: Uninstall erfolgreich"
            glogger -s "$i: Uninstall erfolgreich"
            sed -i .installed -e "/^${i} .*/d"
         else   
            svdrpsend.pl MESG "$i: Fehler bei Uninstall"
            glogger -s "$i: Fehler bei Uninstall"
            STATUS=1
         fi
      fi   
   elif [ "$VAL" = "" ] ; then
      NEW_UPDATES=1 
   elif [ "$(grep ^${i} .installed)" != "" ] ; then
      STATUS=1
   fi   
   if [ $STATUS = 1 ] ; then
      echo "$MYNAME:UPD_${i}:0:B:0:-,uninstall:${INFO}:" >> $UPD_CONF
   else
      echo "$MYNAME:UPD_${i}:0:B:0:-,install:${INFO}:" >> $UPD_CONF
   fi
done

sed -i $ADMIN_CFG_FILE -e "/cfgupd.sh:UPDATE_.*/d" -e "/^:Updates/d" 

if [ -s $UPD_CONF ] ; then
   echo ":Updates" >> $ADMIN_CFG_FILE
   cat $UPD_CONF >> $ADMIN_CFG_FILE 
else   
   echo ":Updates nicht verfuegbar" >> $ADMIN_CFG_FILE
fi

if [ "$REBOOT" != "" ] ; then
   svdrpsend.pl MESG "Update erfolgreich - System wird neu gestartet"
   echo "Rebooting ..."
   shutdown -r now
else
   echo 'Done!'
fi   

if [ $NEW_UPDATES = 1 ] ; then
   svdrpsend.pl MESG "Neue Updates gefunden"
fi

exit 0
