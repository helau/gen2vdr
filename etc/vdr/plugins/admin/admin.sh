#!/bin/bash
source /_config/bin/g2v_funcs.sh
glogger -s "$0 $1"
if [ "$1" = "-init" ] ; then
   echo "vdr startet"
   screen -dm sh -c "/etc/vdr/plugins/admin/setadmconf.sh"
elif [ "$1" = "-start" ] ; then
   echo "admin plugin startet"
   screen -dm sh -c /etc/vdr/plugins/admin/admin_backup.sh
   cp -f /etc/vdr/plugins/admin/admin.conf /etc/vdr/plugins/admin/admin.conf.save
#   /etc/vdr/plugins/admin/setadmconf.pl
elif [ "$1" = "-save" ] ; then
   sh /etc/vdr/plugins/admin/admin_changes.sh
else
   echo "Illegal Parameter <$1>"
fi
