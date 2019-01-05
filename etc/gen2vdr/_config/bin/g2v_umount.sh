#!/bin/bash
PARMS="$@"
logger -s "$0 $PARMS"
eval halevt-umount "$@"
if [ "$1" = "-u" ] ; then
   sleep 3
   /_config/bin/linkvid.sh -check
fi
