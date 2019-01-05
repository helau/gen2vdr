#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ "$UNICABLE" == "Ein" ] ; then
   glogger -s "Enabling Unicable"
   cp -a /_config/install/vdr/scr.conf.unicable /etc/vdr/scr.conf
   cp -a /_config/install/vdr/diseqc.conf.unicable /etc/vdr/diseqc.conf
elif [ "$UNICABLE" == "Aus" ] ; then
   glogger -s "Disabling Unicable"
   rm -f /etc/vdr/scr.conf
   cp -a /_config/install/vdr/diseqc.conf /etc/vdr/diseqc.conf
else
   glogger -s "Syntax: $0 <$UNICABLE>"
fi
