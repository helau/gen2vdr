#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
echo "Collecting information ..."
if [ "$1" = "-v" ] ; then
   VERBOSE=1
   OUTPUT=$2
elif [ "$2" = "-v" ] ; then
   VERBOSE=1
   OUTPUT=$1
else
   VERBOSE=0
   OUTPUT=$1
fi
#set -x
rm -f $(find /log/ /tmp/ -mtime +5 -type f | grep -v "g2v_log_install")
DT=$(date +%m%d%H%M)
LOG_ARCH="/tmp/g2v_log_$DT.tar.xz"

LOG_DIR="/tmp/g2v_log_$(date +%s)"
rm -rf "$LOG_DIR" > /dev/null 2>&1
mkdir -p "$LOG_DIR"
cd "$LOG_DIR"
dmesg -T > dmesg.out 2>&1
biosinfo > bios.out 2>&1
lsmod > lsmod.out 2>&1
lshw > lshw.out 2>&1
lsusb -v > lsusb.out 2>&1
lspci -vn > lspci.out 2>&1
ps -ef > ps.out 2>&1
biosinfo > qmb.out 2>&1
/_config/bin/query_mb.sh >> qmb.out 2>&1
uname -a > uname.out 2>&1
/_config/bin/detect_modules.sh > det_mod.out 2>&1
ls -l /tmp/ > lltmp.out 2>&1
ls -l /usr/local/src/ > llsrc.out 2>&1
cat /proc/meminfo > meminfo.out 2>&1
cat /proc/cpuinfo > cpuinfo.out 2>&1
top -b -d 1 -n 5 > top.out 2>&1 
ifconfig > net.out 2>&1
ping -c 2 -w 5 www.htpc-forum.de >> net.out 2>&1
echo "" >> net.out 2>&1
echo "resolv.conf:" >> net.out 2>&1
cat /etc/resolv.conf >> net.out 2>&1
cat /proc/bus/input/devices > input.out 2>&1
hwinfo > hwinfo.out
mount > mount.out
df > df.out
cat /log/messages > sys.log

FILES="/log/kodi.log.old /log/rc.log /log/dmsg /install.log /_config/update/update.log /etc/gen2vdr/applications  /etc/gen2vdr/remote \
 /etc/vdr.d/conf/vdr /etc/vdr/setup.conf /etc/vdr/channels.conf /etc/X11/xorg.conf /etc/vdr/plugins/admin/admin.conf /root/.kodi/temp/*log* \
 /log/vdr-xine.log /log/hibernate.log /log/Xorg.0.log /root/.xine/config /root/.xine/config_xineliboutput /etc/asound.conf /etc/asound.state \
 /etc/g2v-release /tmp/vdr/vdr_* /etc/X11/xorg.conf.d/*"

[ "$VERBOSE" = "1" ] && FILES="$FILES /log/g2v_log_install.xz /etc/conf.d $(ls /log/messages-2* | tail -n3)"

cp -af $FILES . 2>/dev/null

/_config/bin/get_core.sh > core.out 2>&1

aplay -lL > aplay.out
for i in /proc/asound/card[0-9] ; do
   cnum=${i#*card}
   echo "SoundCard $cnum :" >> sound.out
   amixer contents  -c $cnum >> sound.out
   amixer scontents -c $cnum >> sound.out
   alsactl store $cnum
   echo "" >> sound.out
done

tar -cJf "$LOG_ARCH" .
svdrps MESG "$LOG_ARCH wurde erstellt"
glogger -s "$LOG_ARCH wurde erstellt"
cd ..
rm -rf "$LOG_DIR"
if [ "$OUTPUT" = "-m" ] ; then
   TARGET=$(mount | grep " /media/" | tail -n 1 | cut -f 3 -d " ")
   if [ "$TARGET" != "" ] && [ -d "$TARGET" ] ; then
      OUTPUT="${TARGET}/"
      cp -f "$LOG_ARCH" "$TARGET/"
      sleep 3
      svdrps MESG "$LOG_ARCH wurde nach $TARGET kopiert"
      glogger -s "$LOG_ARCH wurde nach $TARGET kopiert"
   fi
elif [ "$OUTPUT" != "" ] ; then
   cp "$LOG_ARCH" "$OUTPUT.tar.xz"
   svdrps MESG "$LOG_ARCH wurde nach $OUTPUT.tar.xz kopiert"
   glogger -s "$LOG_ARCH wurde nach $OUTPUT.tar.xz kopiert"
fi
