#!/bin/bash
set -x
source /_config/bin/g2v_funcs.sh
glogger -s "$0 $1"

VID_DIR=${1%/}
VID_F1=$(ls "${VID_DIR}/"0*ts |head -n1)
if [ "${VID_F1}" != "" ] ; then
   cd "${VID_DIR}"
   rm -f /tmp/.vidinfo
   ffprobe "${VID_F1}" -show_streams > /tmp/.vidinfo
   WIDTH=$(grep "^width=" /tmp/.vidinfo | cut -f 2 -d "=")
   AR=$(grep "^display_aspect_ratio=" /tmp/.vidinfo | cut -f 2 -d "=")
   HEIGHT=$((WIDTH*${AR#*:}/${AR%:*}))
   mkdir pictures
   rm -f pictures/*
   glogger -s "Erstelle Einzelbilder ... <ffmpeg -i 00001.ts -vf fps=1 -q:v 1 -s ${WIDTH}x${HEIGHT} \"pictures/%05d.jpg\">"
   cat 0*.ts  | ffmpeg -i - -vf fps=1 -q:v 1 -s ${WIDTH}x${HEIGHT} "pictures/%05d.jpg"
else
   echo "No video files in <${VID_DIR}"
fi
