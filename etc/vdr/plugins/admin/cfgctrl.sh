#!/bin/bash
source /_config/bin/g2v_funcs.sh
set -x
MODULES="lirc_serial lirc_atiusb imon lirc_mceusb"
LIRC_SCRIPTS="lircd activylircd irmplircd"
OLD_FBS=",$(grep ":LIRCCFG:" /etc/vdr/plugins/admin/admin.conf|cut -f 6 -d ":"),"
NEW_FBS=""
FOUND=0
ls /_config/install/lircd.conf.*| cut -f 3 -d "." > /tmp/fb
cd /etc/gen2vdr/remote
for i in * ; do
   [ -e ${i}/config ] && [ "$(readlink $i)" = "" ] && echo $i >> /tmp/fb
done

for i in $(cat /tmp/fb|sort -f) ; do
   NEW_FBS="${NEW_FBS}${i},"
   [ "$i" = "$LIRCCFG" ] && FOUND=1
done
sed -i /etc/vdr/plugins/admin/admin.conf -e "s/\(.*\):LIRCCFG:\(.*\):L:.*:\(.*\):\$/\1:LIRCCFG:\2:L:0:${NEW_FBS}Other:\3:/"
if [ "$FOUND" = "0" ] ; then
   $SETVAL LIRCCFG "Other"
fi

[ "$1" = "-check" ] && exit

for i in $MODULES ; do
   if [ "$i" != "imon" ] || [ "${LCD//*imon*}" != "" ] ; then
      modprobe -r $i > /dev/null 2>&1
      /_config/bin/module-update.sh del $i >/dev/null
   fi
done

glogger -s "ADMIN - REMOTE: $REMOTE"
PLG_remote=0
ACT_LIRC=""
REM_CONF="/_config/install/vdr/remote.conf"
/_config/bin/module-update.sh del lirc_serial

if [ "$REMOTE" = "Tastatur" ] ; then
   ACT_LIRC=""
elif [ "$REMOTE" = "DVB" ]; then
   ACT_LIRC=""
   PLG_remote=10
elif [ "$REMOTE" = "ActivyFB" ]; then
   ACT_LIRC="activylircd"
elif [ "$REMOTE" = "IRMP" ]; then
   ACT_LIRC="irmplircd"
elif [ "$REMOTE" = "MedionX10" ]; then
   /_config/bin/module-update.sh add ati_remote
   ACT_LIRC=""
elif [ "$REMOTE" = "MCEUSB" ]; then
   /_config/bin/module-update.sh add mceusb
   ACT_LIRC=""
elif [ "$REMOTE" = "Imon" ]; then
   ACT_LIRC=""
elif [ "$REMOTE" = "ya_usbir" ]; then
   ACT_LIRC="lircd"
elif [ "$REMOTE" = "AtricUSB" ]; then
   ACT_LIRC="lircd"
elif [ "$REMOTE" = "LircSerial" ]; then
   ACT_LIRC="lircd"
else
   REM_CONF=""
fi

[ "$REM_CONF" != "" ] && cp $REM_CONF /etc/vdr/remote.conf

#if [ "$(readlink /etc/lircd.conf)" == "" ] || [ ! -s /etc/lircd.conf ] ; then
#   rm -f /etc/lircd.conf
#   ln -s lirc/lircd.conf /etc/lircd.conf
#fi

if [ -f /_config/install/lircd.conf.$LIRCCFG ] ; then
   [ -f /etc/lirc/lircd.conf.d/lircd.conf ] && mv -f /etc/lirc/lircd.conf.d/lircd.conf /etc/lirc/lircd.conf/lircd.conf.save
   cp -f /_config/install/lircd.conf.$LIRCCFG /etc/lirc/lircd.conf.d/lircd.conf  >/dev/null 2>&1
elif [ "$LIRCCFG" != "Other" -a "$LIRCCFG" != "" -a ! -e /etc/gen2vdr/remote/${LIRCCFG}/config ]  ; then
   glogger -s "Unknown LIRCCFG parameter $1"
#   exit 1
fi

[ "$REMOTE" == "Other" -a "$LIRCCFG" == "Other" ] && exit

if [ "$ACT_LIRC" = "" ] ; then
   /etc/init.d/irexec stop >/dev/null 2>&1
   rc-update del irexec default
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<remoteaskeyboard>true</remoteaskeyboard>%<remoteaskeyboard>false</remoteaskeyboard>%" >/dev/null 2>&1
   DOIT="1"
else
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<remoteaskeyboard>false</remoteaskeyboard>%<remoteaskeyboard>true</remoteaskeyboard>%" >/dev/null 2>&1
   DOIT=""
fi

for i in $LIRC_SCRIPTS ; do
   if [ "$i" = "$ACT_LIRC" -o "$DOIT" = "1" ] ; then
      sed -i /etc/init.d/$i -e "s/before irexec.*/provide lirc/"
      DOIT=0
   else
      sed -i /etc/init.d/$i -e "s/provide lirc.*/before irexec/"
   fi
done

for i in $LIRC_SCRIPTS ; do
   /etc/init.d/$i stop >/dev/null 2>&1
   if [ "$i" != "$ACT_LIRC" ] ; then
      rc-update del $i boot >/dev/null 2>&1
      rc-update del $i default >/dev/null 2>&1
   fi
done

if [ "$ACT_LIRC" != "" ] ; then
   if [ "$(grep "mplayer.ControlMode" $VDR_CONFIG_DIR/setup.conf)" != "" ] ; then
      sed -i $VDR_CONFIG_DIR/setup.conf -e "s/^mplayer\.ControlMode.*/mplayer\.ControlMode = 1/"
   else
      echo "mplayer.ControlMode = 1" >> $VDR_CONFIG_DIR/setup.conf
   fi
   rc-update add $ACT_LIRC boot
   /etc/init.d/$ACT_LIRC start >/dev/null 2>&1
   if [ -e /etc/gen2vdr/remote/$REMOTE ] ; then
      cd /etc/gen2vdr/remote
      rm -f act 2>/dev/null
      ln -s $REMOTE act
   fi
else
   if [ -e /etc/gen2vdr/remote/$LIRCCFG ] ; then
      cd /etc/gen2vdr/remote
      rm -f act 2>/dev/null
      ln -s $LIRCCFG act
   fi
fi
$SETVAL -x PLG_remote $PLG_remote

echo 'Done!'
