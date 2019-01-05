#!/bin/bash
#set -x
KODI_USER=root
KODI_HOME=/root/.kodi
#KODI_DIR="/opt/KODI/appl"
#KODI_DIR="/opt/KODI/appl"
KODI_DIR=/usr
KODI_EXEC="${KODI_DIR}/bin/kodi"

source /_config/bin/g2v_funcs.sh
glogger -s $0
LOG_FILE="/log/$(basename ${0%.*}).log"
echo "Started at: $(date +'%F %R')" > ${LOG_FILE}
exec 1> >(tee -a ${LOG_FILE}) 2>&1

export LANG=de_DE.utf8
export LC_ALL=de_DE.utf8

PR=$(pidof -x ratpoison gg_launcher.pl)
[ "$PR" != "" ] && kill -9 $PR

#screen -dm sh -c "/_config/bin/gg_setactapp.sh KODI"
screen -dm sh -c /root/.MakeMKV/getkey.sh

cp -av ${KODI_HOME}/temp/kodi.log /log/kodi.log.old
rm -rf ${KODI_HOME}/temp/* /tmp/kodi 2>/dev/null
ln -s  ${KODI_HOME}/temp /tmp/kodi
ln -sf  ${KODI_HOME}/temp/kodi.log /log/
chown -R ${KODI_USER}:${KODI_USER} ${KODI_HOME}

# look for airplay/avahi
if [ "$(grep "<airplay>true</airplay>" /root/.kodi/userdata/guisettings.xml)" != "" ] ; then
   [ "$(pidof avahi-daemon)" == "" ] && /etc/init.d/avahi-daemon start
fi
sed -i /usr/share/kodi/addons/skin*/xml/*Button*xml -e 's%<onclick>Quit()</onclick>%<onclick>System.Exec("/_config/bin/kodi_stop.sh")</onclick>%'

/_config/bin/g2v_display.sh 0
screen -dm sh -c "/_config/bin/scanvdr.sh"
screen -dm sh -c "sleep 1;iecset audio on"
A=$(date +%s)
#su $KODI_USER -c $KODI_EXEC
$KODI_EXEC
RC=$?
B=$(date +%s)
glogger -s "Kodi stopped 0 - RC: $RC $A $B"
rm -f "$GG_ACTAPP_FILE"
#kill -9 $(ps x |grep /usr/bin/dbus-daemon |grep fork|cut -b 1-5) >/dev/null 2>&1
#kill -9 $(pidof -x kodi kodi.bin scanvdr.sh  2>/dev/null) 2>/dev/null
#creen -dm sh -c "ratpoison -d $DISPLAY"
#screen -dm sh -c "/etc/init.d/g2vgui stop; sleep 3; /etc/init.d/g2vgui start"
