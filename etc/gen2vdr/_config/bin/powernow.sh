#! /bin/bash
source /_config/bin/g2v_funcs.sh
#
# powernow aktivieren
MODUL=powernow-k8  # hier das gewuenschte mudul eintragen
#DEAM=cpudyn        # hier das gewuenschte programm das die Taktung uebernehm soll
DEAM=cpufrequtils   # hier das gewuenschte programm das die Taktung uebernehm soll
modprobe $MODUL > /dev/null 2>&1

if [ "$(lsmod | grep "^${MODUL/-/_}")" = "" ] ; then
   glogger -s "$MODUL kann nicht geladen werden"
else
   glogger -s "Aktiviere powernow ..."
   /_config/bin/module-update.sh add $MODUL
fi

echo "Ueberpruefe auf AMD powernow"
if [ ! -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor -a ! -e /proc/cpufreq ]; then
   glogger -s "CPU ist nicht powernow kompatibel"
   rc-update del $DEAM default > /dev/null 2>&1
   /_config/bin/module-update.sh del $MODUL
   exit
fi

rc-update add $DEAM default
glogger -s "$DEAM wurde zu runlevel hinzugefuegt"
/etc/init.d/$DEAM start
