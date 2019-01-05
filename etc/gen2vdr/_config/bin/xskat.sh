#!/bin/bash
source /_config/bin/g2v_funcs.sh

#resolution="$(xrandr | tail -n 1 | tr -s " " | cut -f 2 -d " ")"
[ ! -d /games/xskat ] && mkdir /games/xskat
cd /games/xskat

#/usr/games/bin/xskat -lang german -frenchcards -display :0 -geometry 1024x768 -fastdeal -small
#xrandr -s "640x480"
/usr/games/bin/xskat -g 640x480 -keyboard 2 -lang german -d ${DISPLAY:-:0.0} #-frenchcards -display :0 -fastdeal -large

