#!/bin/bash
FN="/etc/vdr/plugins/burn/templates/bg_$1.png"
if [ -f $FN ]; then
   cp -f $FN "/etc/vdr/plugins/burn/menu-bg.png"
else
   echo "<$FN> nicht vorhanden"
fi
