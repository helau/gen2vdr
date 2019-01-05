#!/bin/bash
source /etc/vdr.d/conf/gen2vdr.cfg

execCmd() {
   echo "$(date +"%y%m%d %T") <$1>"
   $1
}

msgInfo() {
   echo ""
   echo "$(date +"%y%m%d %T") <$1>"
   echo ""
}

/_config/bin/query_con.sh -switch

# Install updates
MD5_FILE="/_config/update/g2v_md5_fixes"
if [ -f $MD5_FILE ] ; then
   for i in $(grep "g2v_up.*\.t*" $MD5_FILE | cut -f 3 -d " ") ; do
      FN=$(echo $i | cut -f 1 -d ".")
      if [ -f /_config/update/$FN.sh ] ; then
         execCmd "bash /_config/update/$FN.sh"
      fi
   done
   rm $MD5_FILE > /dev/null 2>&1 
   /_config/bin/query_con.sh -switch
fi

chmod +x /_config/bin/* /_config/*/*.sh /usr/bin/*
/etc/vdr/plugins/admin/cfgctrl.sh -check
/etc/vdr/plugins/admin/cfglcd.sh -check
/etc/vdr/plugins/admin/cfgnet.sh

# Initialize Konfiguration
#execCmd "sh /_config/bin/detect_modules.sh"
execCmd "/_config/bin/default_cfg.sh"
execCmd "/_config/bin/detect_ctrl.sh"
execCmd "/_config/bin/detect_cpu.sh"
execCmd "/_config/bin/detect_board.sh"
execCmd "/_config/bin/unmute.sh"

/_config/bin/query_con.sh -switch

if [ -f /mnt/data/g2v-backup/.do_migrate ] ; then
   # Migrate old config
   execCmd "/_config/bin/g2v_migrate.sh"
   rm /mnt/data/g2v-backup/.do_migrate
fi

mkdir /mnt/data/audio/images >/dev/null 2>&1
cp -f /etc/vdr/plugins/mp3/* /mnt/data/audio/images/ >/dev/null 2>&1
cp /_config/install/vdr/setup.conf /etc/vdr/

VDRUSER="root"

chown ${VDRUSER}:users /mnt/data/* /mnt/data/*/* > /dev/null 2>&1
chown -R ${VDRUSER} /etc/vdr > /dev/null 2>&1
chown -R vdr:users /home/vdr > /dev/null 2>&1

rm -f /_config/status/* > /dev/null 2>&1

chmod +x /_config/bin/* /_config/*/*.sh /usr/bin/* > /dev/null 2>&1
chmod 777 /tmp $(readlink /tmp) /log $(readlink /log) $(find /log -follow -type d) > /dev/null 2>&1
chown -R portage:portage /usr/portage /usr/portage/* > /dev/null 2>&1

execCmd "/_config/bin/detect_dvb.sh"
execCmd "/_config/bin/detect_x.sh"

[ -f /default.conf ] && /_config/bin/g2v_setvars.sh /default.conf

msgInfo "Einstellungen konfigurieren ..."

[ -f /etc/vdr/plugins/admin/admin.conf.save ] && rm -f /etc/vdr/plugins/admin/admin.conf.save
sh /etc/vdr/plugins/admin/admin_changes.sh -f

msgInfo "System wird initialisiert ..."

ldconfig
depmod -a

# Update fontconfig
#for i in /usr/share/fonts /var/cache/fontconfig /root/.fontconfig /usr/share/fonts/* /var/cache/fontconfig/* /root/.fontconfig/* ; do
#   [ -e $i ] && touch $i > /dev/null 2>&1
#done
#fc-cache -f

# Lade Boot-Manager
source /etc/vdr.d/conf/vdr

lilo

sync&&sync > /dev/null

rm -rf /tmp/g2v_log_*
echo "Log wird erstellt ..."
/_config/bin/g2v_log.sh
mv /tmp/g2v_log_*.tar.xz /log/g2v_log_install.tar.xz
echo ""
echo "Weitere Anpassungen ueber VDR-Menu->Einstellungen->Plugins->Admin"
echo "Das Menu wird mit der Tab-Taste aufgerufen."
echo ""
echo "Das Passwort fuer den root-user lautet: <gen2vdr>"
echo ""
