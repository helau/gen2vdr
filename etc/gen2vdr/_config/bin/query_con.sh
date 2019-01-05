#!/bin/bash
CON=$(ps x | grep -m 1 "$0" | sed -e "s/.*tty//" | cut -b 1)
if [ "$1" = "-switch" ] && [ ! -e /tmp/.shutdown ] ; then
   chvt $CON
else   
   echo $CON
fi   
