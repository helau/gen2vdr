#!/bin/bash
/_config/bin/gg_setsofthdd.sh deta
APPS=$(/_config/bin/getproctree.sh xinit X /_config/bin/gg_* /etc/gen2vdr/applications/* /_config/bin/xwatch.sh) > /dev/null 2>&1
kill $APPS > /dev/null 2>&1
sleep 1
for i in 1 2 3 ; do
   APPS=$(/_config/bin/getproctree.sh xinit X /_config/bin/gg_* /etc/gen2vdr/applications/* /_config/bin/xwatch.sh) > /dev/null 2>&1
   [ "$APPS" = "" ] && break
   kill $APPS > /dev/null 2>&1
   sleep 1
done
kill -9 $(/_config/bin/getproctree.sh xinit X xine vdr-sxfe /_config/bin/gg_* /etc/gen2vdr/applications/*  /_config/bin/xwatch.sh) > /dev/null 2>&1
killall -9 irexec inputevxd
modprobe -r nvidia > /dev/null 2>&1
