#!/bin/bash
# Script to start installation part 2
mv -f /etc/local.d/g2v.start.org /etc/local.d/g2v.start
mv -f /etc/local.d/g2v.stop.org /etc/local.d/g2v.stop
rm -f /etc/local.d/g2vinit.start

echo "$(date +"%y%m%d %T") Starte <$0>" >> /install.log
echo "" >> /install.log
mount >> /install.log

MODULES="lirc_serial lirc_atiusb imon lirc_mceusb"
LIRC_SCRIPTS="lircd activylircd smtlircd irtrans-server inputlircd"

rm -f /etc/conf.d/modules /etc/modprobe.d/g2v.conf
for i in $MODULES ; do
   if [ "$i" != "imon" ] || [ "${LCD//*imon*}" != "" ] ; then
      modprobe -r $i > /dev/null 2>&1
      /_config/bin/module-update.sh del $i >/dev/null
   fi
done
for i in $LIRC_SCRIPTS ; do
   /etc/init.d/$i stop >/dev/null 2>&1
   if [ "$i" != "$ACT_LIRC" ] ; then
      rc-update del $i boot >/dev/null 2>&1
      rc-update del $i default >/dev/null 2>&1
   fi
done
for i in vdr alsasound ; do
   rc-update add $i boot
done
for i in g2vgui ; do
   rc-update add $i default
done
find /etc -type d -newer /install.log -or -type f -newer /install.log -exec touch {} \;
touch -d "+3 hours" /var/cache/fontconfig /var/cache/fontconfig/*
#touch /usr/X11R6/lib/X11/fonts/* /var/cache/fontconfig
echo "Starte Installation Teil 2"
echo "#!/bin/bash" > /tmp/.autostart
echo "/_config/install/init.sh 2>&1 | tee -a /install.log" >> /tmp/.autostart
echo "/_config/bin/mkac.sh" >> /tmp/.autostart
echo "g2v-setup" >> /tmp/.autostart
echo "g2v-setup-receiver" >> /tmp/.autostart
echo "echo \"Das System wird nun neu gestartet\"" >> /tmp/.autostart
echo "reboot" >> /tmp/.autostart
echo "chvt 1" >> /tmp/.autostart
chmod +x /tmp/.autostart
openvt -c 9 -s -f -- /tmp/.autostart
