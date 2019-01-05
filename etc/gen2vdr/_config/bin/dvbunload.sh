#!/bin/bash
cd /usr/local/src/DVB/v4l
#set -x
ALL_MODS=$(ls *.ko|cut -f 1 -d "."| tr "-" "_")
for i in $ALL_MODS ; do
   modprobe -r $i >/dev/null 2>&1
done   
