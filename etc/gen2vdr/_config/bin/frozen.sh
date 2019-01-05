#!/bin/bash
source /_config/bin/g2v_funcs.sh

if ! test -d /games/frozen ; then
   mkdir /games/frozen
fi
cd /games/frozen

/_config/bin/frozen-fb.sh

#/usr/games/bin/frozen-bubble --very-slow-machine
/usr/games/bin/frozen-bubble --fullscreen --slow-machine

/_config/bin/activy_fboff.sh
