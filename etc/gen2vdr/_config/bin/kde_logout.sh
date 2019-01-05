#!/bin/bash
USERS="$(who | grep " \:0" | cut -f 1 -d " ")"
if [ "$USERS" != "" ] ; then
   for i in $USERS ; do
      su $i -c "DISPLAY=${DISPLAY:-:0.0} kdeinit4_shutdown"
   done
   killall xmessage
fi
