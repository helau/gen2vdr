#!/bin/bash
source /_config/bin/g2v_funcs.sh

X_CONSOLE=7

if [ -f /tmp/.vdrdisabled ] ; then
   NEW_CON="VDR"
else   
   NEW_CON="X"
fi
logger -s "$0 <$1><$2> $NEW_CON"
sh /_config/bin/switch_console $NEW_CON
