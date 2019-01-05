#!/bin/bash
PARM=""
if [ "$1" != "" ] ; then
   PARMS="-e \"$1\""
else
   PARMS=""
fi
konsole $PARMS &
while [ "$(pidof konsole)" != "" ] ; do
   sleep 3
done
