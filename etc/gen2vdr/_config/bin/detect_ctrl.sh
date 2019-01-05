#!/bin/bash
source /_config/bin/g2v_funcs.sh

autoload() {
   /_config/bin/module-update.sh add "$1"
}

activate_plugin() {
   $SETVAL "PLG_$1" $2
}

set -x
REM_DEV="Other"
LIRC_CONF="Other"

LIRC_DRV=""
LIRC_CONF="Other"
ALL_MODS=" $(lsmod | cut -f 1 -d " " |tr "\n" " ") "

echo "Checking for iMON"
if [ "${ALL_MODS/* imon */}" = "" ] ; then
   LIRC_DRV="imon"
   DRV=imon
   PLG=lcdproc

   if [ "$(lsusb |grep -i "15c2:0038")" != "" ] ; then
      sed -i /etc/LCDd.conf -e "s/^Protocol=0/Protocol=1/"
      DRV=imonlcd
      PLG=imonlcd
   elif [ "$(lsusb |grep -i "15c2:ffdc")" != "" ] ; then
      if [ "$(dmesg | grep -i iMON | grep LCD)" != "" ] ; then
         sed -i /etc/LCDd.conf -e "s/^Protocol=1/Protocol=0/"
         DRV=imonlcd
         PLG=imonlcd
      fi
   fi
   sed -i /etc/LCDd.conf -e "s/^Driver=.*G2V.*/Driver=${DRV}     # G2V/" -e "s/^ServerScreen=.*/ServerScreen=no/"
   $SETVAL LCD $DRV
   activate_plugin "${PLG}" "99"
   [ "$PLG" == "lcdproc" ] && rc-update add LCDd boot >/dev/null 2>&1
   REM_DEV=Imon
   LIRC_CONF=Harmony_Imon_R200
fi

echo "Checking for ATIUSB"
if [ "${ALL_MODS/* ati_remote */}" = "" ] ; then
   LIRC_DRV=""
   REM_DEV=MedionX10
   LIRC_CONF=MedionX10
   /_config/bin/module-update.sh add ati-remote
fi

echo "Checking for MCE"
if [ "${ALL_MODS/* mceusb */}" = "" ] ; then
   LIRC_DRV="mceusb"
   REM_DEV=MCEUSB
   LIRC_CONF=MCEUSB
   /_config/bin/module-update.sh add mceusb
fi

echo "Checking for HamaFB"
if [ "$(lsusb |grep -i "05a4:9881")" != "" ] ; then
   LIRC_DRV=""
   REM_DEV=MedionX10
   LIRC_CONF=Hama52451
fi

echo "Checking for StreamzapFB"
if [ "$(lsusb |grep -i "0e9c:0000")" != "" ] ; then
   LIRC_DRV=""
   REM_DEV=MedionX10
   LIRC_CONF=Streamzap
fi

echo "Checking for PollinCyberlink FB"
if [ "$(lsusb |grep "0766:0204")" != "" ] ; then
   LIRC_DRV=""
   REM_DEV=MedionX10
   LIRC_CONF=PollinCyberlink
fi

echo "Checking for Reycom FB"
if [ "$(lsusb |grep -i "0bc7:000c")" != "" ] ; then
   LIRC_DRV=""
   REM_DEV=MedionX10
   LIRC_CONF=Reycom
fi

[ "$LIRC_DRV" != "" ] && autoload $LIRC_DRV

$SETVAL REMOTE $REM_DEV
$SETVAL -x LIRCCFG $LIRC_CONF
