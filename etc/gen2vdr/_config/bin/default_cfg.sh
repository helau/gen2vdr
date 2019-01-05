#!/bin/bash
#
source /_config/bin/g2v_funcs.sh

DEFAULT_PLUGINS="osdteletext softhddevice skindesigner epgsearch tvguideng femon live dbus2vdr weatherforecast admin"

# These plugins will be used after installation
#if [ "$(readlink /dev/cdrom)" != "" ] ; then
#   DEFAULT_PLUGINS="dvd $DEFAULT_PLUGINS "
#fi

XRES="800x600"

autoload() {
   /_config/bin/module-update.sh add "$1"
}

activate_plugin() {
   $SETVAL "PLG_$1" $2
}

test_directisa() {
   TEST_DATE="020200002002"
   hwclock --hctosys --directisa
   ACT_DATE=$(date +%m%d%H%M%Y.%S)
   date $TEST_DATE
   hwclock --systohc --directisa
   date $ACT_DATE
   hwclock --hctosys --directisa
   TD=$(date +%m%d%H%M%Y)
   date $ACT_DATE
   if [ "$TD" = "$TEST_DATE" ] ; then
      echo "directisa is working"
      DI=1
   else
      echo "RTC is necessary"
      DI=0
   fi
   hwclock --systohc --directisa
   $SETVAL "DIRECTISA" $DI
}

cp /etc/vdr/plugins/admin/admin.conf.default /etc/vdr/plugins/admin/admin.conf
sh /etc/vdr/plugins/admin/setvdrconf.sh -q
test_directisa

sh /etc/vdr/plugins/admin/cfgplg.sh $DEFAULT_PLUGINS

rc-update del activylircd >/dev/null 2>&1
rc-update del virtualbox-guest-additions boot >/dev/null 2>&1

BOARD=$(/_config/bin/query_mb.sh)

case "$BOARD" in
   VirtualBox)
      rc-update add virtualbox-guest-additions boot >/dev/null 2>&1
#      /_config/bin/module-update.sh add vboxvideo
      ;;
   ACTIVY)
      $SETVAL LIRC ActivyFB
      autoload "i2c-dev"
      autoload "i2c-i801"
      autoload "natsemi"
      modprobe natsemi
      activate_plugin "alcd" "99"
      $SETVAL LCD activy3
      ;;
   *)
      ;;
esac

$SETVAL SCREEN_RESOLUTION $XRES
