#!/bin/bash
source /_config/bin/g2v_funcs.sh
export LANG=de_DE.UTF-8
export LANGUAGE=de_DE.UTF-8
export LC_ALL=de_DE.UTF-8
pulseaudio --start
firefox --display=${DISPLAY:-:0.0} "javascript:resizeTo(screen.availWidth,screen.availHeight);self.moveTo(0,0)"
killall pulseaudio
