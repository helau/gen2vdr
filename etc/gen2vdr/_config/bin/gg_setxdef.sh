#!/bin/bash
source /_config/bin/g2v_funcs.sh

SETX="/tmp/~setx.sh"

if [ -e "$SETX" ]; then
   sh "$SETX"
else
   xrandr -q >/tmp/.xset
   if [ -s /tmp/.xset ] ; then
      echo -n "xrandr -d $DISPLAY" >$SETX
      cat /tmp/.xset | while read i ; do
         if [ "${i/* connected */}" == "" ] ; then
            echo -n " --output ${i%% *}"
            i=${i#* connected }
            echo -n " --mode ${i%%+*}"
         elif [ "${i##*\*}" != "$i" ] ; then
            i=${i%%\**}
            echo -n " --rate ${i##* }"
         fi
      done >>$SETX
      glogger -s "SETX: $(cat $SETX)"
   fi
fi
