#!/bin/bash
echo ""
echo "mkcfg start"

EXCL=/tmp/mkcfg.excl
ERR=0
for i in $(find /_config/ /etc/vdr/ /etc/vdr.d/ /etc/gen2vdr/ -name "*.sh") $(find /etc/gen2vdr/applications/ -type f -name "[01]*"); do
   bash -n "$i"
   if [ "$?" != "0" ] ; then
      echo "Syntax error in <$i>"
      ERR=1
   fi
done
chmod +x /_config/bin/* /usr/local/bin/*
chown -R root:vdr /_config/* /etc/vdr* /usr/local/*
if [ "$ERR" != "0" ] ; then
   "Abbruch mit ctrl-c - Weiter mit enter"
   read i
fi

TARGET_DIR="${TARGET_DIR:=/mnt/data/backup}"
XZ_OPTS=${XZ_OPTS:="-2"}
TAR_OPTS=${TAR_OPTS:="-cJpf"}

chmod +x /_config/*/*.sh /_config/*/*/*.sh /etc/vdr/runvdr /_config/bin/* > /dev/null 2>&1
chmod +x /etc/*/*.sh /etc/init.d/* /etc/*/*/*.sh /etc/*/*/*/*.sh > /dev/null 2>&1
rm /etc/vdr/plugins/admin/~* /etc/sysconfig/* > /dev/null 2>&1

cd /

echo -ne "admin.conf.sav*\nvdr.old*\n" >${EXCL}
rm -f ${TARGET_DIR}/g2v_config.tar.xz
if [ "$1" == "-b" ] ; then
   touch /_config/.restored
else
   rm -f /_config/.restored
   {
   echo -ne "./etc/init.d/net.e*\n./etc/runlevels/boot/net.e*\n./etc/init.d/net.w*\n./etc/resolv.conf*\n./etc/env.d/*proxy\n./etc/wicd/*-settings.conf\ncookies.sqlite*\n"
   echo -ne "./etc/conf.d/modules\n./etc/machine-id\n./etc/modprobe.d/g2v.conf\n./etc/oscam/oscam.server\n./etc/eixrc.backup.*\n./etc/gen2vdr/remote/act\n./etc/udev/rules.d/*persistent*.rules\n"
   echo -ne "./root/.local\n./root/.screen\n/root/kodi*.log\n./root/.subversion/*\n./root/.ssh/*\n./root/.*_history\ndead.letter\n./root/.kodi/userdata/addon_data/plugin.video.prime_instant\n"
   echo -ne "./root/.kodi/tmp/*\n./root/.cache/*\n./home/vdr/.cache/*\n"
   } >>${EXCL}
   cd /
fi

export XZ_OPT=$XZ_OPTS

tar $TAR_OPTS ${TARGET_DIR}/g2v_config.tar.xz --exclude-from=$EXCL ./etc ./_config ./root ./home

echo "mkcfg end"
echo ""
