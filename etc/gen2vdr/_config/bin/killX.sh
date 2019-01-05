#!/bin/bash
touch /tmp/.stopxvdr
/_config/bin/gg_setsofthdd.sh deta
kill -9 $(pidof xbmc) $(pidof -x freevo_start.sh freevo x2vdr.sh xbmc.bin xbmc-start.sh xine vdr-xine.sh vdr-sxfe X unclutter)>/dev/null 2>&1
kill -9 $(ps x |grep /usr/bin/dbus-daemon |grep fork|cut -b 1-5) >/dev/null 2>&1
rm -rf /tmp/.X* 2>/dev/null
modprobe -r nvidia >/dev/null 2>&1
