#!/bin/bash
#
source /_config/bin/g2v_funcs.sh
BACKUP_DIR="/mnt/data/g2v-backup"
OLD_CONFIG_FILES="$BACKUP_DIR/etc/vdr.d/conf/vdr $BACKUP_DIR/etc/conf.d/vdr"
COPY_FILES="${BACKUP_DIR}/etc/hosts ${BACKUP_DIR}/etc/asound.conf ${BACKUP_DIR}/etc/vdr/*.conf ${BACKUP_DIR}/etc/oscam"

checkvar() {
   case "$1" in
      LIRC)
#         for i in "/_config/install/lircd.conf.$2" "/etc/vdr/remote.conf" "/etc/lircd.conf" "/etc/lirc/lircd.conf" ; do
#            if [ -f "${BACKUP_DIR}${i}" ] ; then
#               cp -vf "${i}" "${i}.mig"
#               cp -vf "${BACKUP_DIR}${i}" "$i"
#            fi
#         done

         REMOTE="Other"
         LIRCCFG="Other"
         if [ "$2" = "ActivyFB" -o "$2" = "SMT7020FB" -o "$2" = "Tastatur" ] ; then
            REMOTE="$2"
         elif [ "$2" = "MedionX10" ] ; then
            REMOTE="$2"
            LIRCCFG="$2"
         elif [ "$2" = "Nexus" ] ; then
            REMOTE="DVB"
         elif [ "$2" != "Other" ] ; then
            REMOTE="LircSerial"
            LIRCCFG="$2"
         fi
         $SETVAL REMOTE $REMOTE
         $SETVAL LIRCCFG $LIRCCFG
         if [ -f ${BACKUP_DIR}/etc/vdr/remote.conf ] ; then
            sed -i /etc/vdr/remote.conf -e "/\.Jump...Slow/d"  -e "s/\.JumpRew/\.Prev/g"  -e "s/\.JumpFwd/\.Next/g"
         fi
         if [ "$(grep XKeySym /etc/vdr/remote.conf)" = "" ] ; then
            grep XKeySym /_config/install/vdr/remote.conf.org >> /etc/vdr/remote.conf 
         fi
         ;;
      PLUGINS)
         sh /etc/vdr/plugins/admin/cfgplg.sh "$2"
         for i in $PLUGINS ; do
            cp -av ${BACKUP_DIR}/etc/vdr.d/plugins/$i /etc/vdr.d/plugins/
         done
         for i in ${BACKUP_DIR}/etc/vdr.d/plugins/*/* ; do
            [ ! -e "${i#${BACKUP_DIR}}" ] && cp -av "${i}" "${i#${BACKUP_DIR}}"
         done
         for i in ${BACKUP_DIR}/etc/vdr.d/plugins/[0-9]* ; do
            [ ! -e "${i#${BACKUP_DIR}}" ] && cp -dv "${i}" "${i#${BACKUP_DIR}}"
         done
         ;;
      IPADR|DHCP|NAMESERVER|NET|HOSTNAME|GATEWAY|LIRCCFG|REMOTE)
         $SETVAL $1 "$2"
         ;;
      *)
         ;;
   esac
}
if [ -f $BACKUP_DIR/etc/vdr/channels.conf ] ; then
   cp -vf $BACKUP_DIR/etc/vdr/channels.conf /etc/vdr/channels.conf
fi

FOUND=0
#set -x
for i in $OLD_CONFIG_FILES ; do
   if [ -e $i ] ; then
      FOUND=1
      logger -s "Alte Konfiguration wird migriert ..."
      OLDVARS=$(grep -v "^#" $i | grep "=" | cut -f 1 -d "=")

      for j in $OLDVARS ; do
         VAL=$(grep "^${j}=" $i | cut -f 2 -d '=')
         [ "$VAL" != "" ] && checkvar $j "${VAL//\"/}"
      done
      break
   fi
done
for i in $COPY_FILES ; do
   if [ -e $i ] ; then
      FOUND=1
      logger -s "$i wird kopiert ..."
      cp -avf "$i" "${i#${BACKUP_DIR}}" |logger -s
   fi
done
[ $FOUND -eq 0 ] && logger -s "Nichts zum Migrieren gefunden"
