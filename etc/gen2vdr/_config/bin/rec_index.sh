#!/bin/bash
source /_config/bin/g2v_funcs.sh

VID_DIR="${1%/}"

if [ -e ${VID_DIR}/00001.ts ] ; then
   [ -s "${VID_DIR}/index" ] && rm "${VID_DIR}/index"
   screen -dm sh -c "vdr --genindex=$VID_DIR"
   glogger "Index fuer <$VID_DIR> wird angelegt"
elif [ -e ${VID_DIR}/001.vdr ] ; then
   [ -s "${VID_DIR}/index.vdr" ] && rm "${VID_DIR}/index.vdr"
   screen -dm sh -c "cd $VID_DIR; genindex"
   glogger "Index fuer <$VID_DIR> wird angelegt"
else
   glogger "Keine Aufnahme in <$VID_DIR> vorhanden"
fi
