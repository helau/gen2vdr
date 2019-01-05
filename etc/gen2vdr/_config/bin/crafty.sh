#!/bin/bash
if ! test -d /games/crafty ; then
   mkdir /games/crafty
fi
export CHESSDIR="/games/crafty"
cd /games/crafty
/usr/games/bin/xboard -fcp /usr/games/bin/crafty -d ${DISPLAY:-:0.0}
