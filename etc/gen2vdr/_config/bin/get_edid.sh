#! /bin/bash

# litte script to get EDID informations from Monitors
# and write it in to a edid.bin file
# by 3PO

XORGCONFDIR="/etc/X11"
LOGFILE="/log/Xorg.0.log"

[ "$1" = "-f" ] && rm -fv $XORGCONFDIR/edid.bi*

cd $XORGCONFDIR

echo -e '\n'
if [ "$(pidof X)" != "" ] ; then
   VS="1"
   /etc/init.d/xbmc stop
   /etc/init.d/g2vgui stop
   sleep 2
fi

X -logverbose 6  > /dev/null 2>&1 &
echo ""

i=10
while [ $i -gt 0 ]; do
   echo -en "wait... $i \r"
   sleep 1
   i=$(($i-1))
done

echo ""
killall X
sed -n "/- Modes/,/- End/p" /var/log/Xorg.0.log | sed "s/.*(0)://g" |egrep EDID |tee edidinfo.txt
echo ""
nvidia-xconfig --extract-edids-from-file=$LOGFILE
sleep 1
[ "$VS" != "" ] && /etc/init.d/g2vgui start
echo ""
