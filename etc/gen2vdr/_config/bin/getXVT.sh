#!/bin/bash
#set -x
XPID=$(pidof X)
XC=""
if [ "$XPID" != "" ] ; then
   XC="$(ps x | grep "$XPID tty" | grep -m 1 " X " | sed -e "s/.* tty//" | cut -f 1 -d " ")"
   [ "$XC" = "" ] &&  XC="$(ps x | grep "$XPID " | grep -m 1 " vt" | sed -e "s/.* vt//" | cut -f 1 -d " ")"
   [ "$XC" = "" ] &&  XC=7
   if [ "$XC" != "" ]; then
      echo $XC
      if [ "$1" = "-a" ] ; then
         chvt $XC & >/dev/null 2>&1
      fi
   fi
fi
