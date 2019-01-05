#!/bin/bash
source /_config/bin/g2v_funcs.sh
source /etc/conf.d/g2vgui

CMD="xinit $XINITOPTS -- $XVT $XSERVEROPTS"

while : ; do
   glogger -s "Starting <$CMD>"
   $CMD
   modprobe -r nvidia
   /_config/bin/gg_setsofthdd.sh deta
   chvt 7
   sleep 3
done
