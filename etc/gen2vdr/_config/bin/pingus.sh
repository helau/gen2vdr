#!/bin/bash
source /_config/bin/g2v_funcs.sh

if ! test -d /games/pingus ; then
   mkdir /games/pingus
fi
cd /games/pingus

/usr/games/bin/pingus -g 640x480 --fast-mode --language=de --fullscreen
#/usr/games/bin/pingus --geometry 640x480 --enable-swcursor --min-cpu-usage --fast-mode --fullscreen
#/usr/games/bin/pingus --enable-swcursor --fast-mode --fullscreen

