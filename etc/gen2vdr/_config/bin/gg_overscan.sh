#!/bin/bash
source /_config/bin/g2v_funcs.sh
VAL=""
if [ "$1" = "-l" ] ; then
   VAR="OVERSCAN_LEFT"
   VAL=$OVERSCAN_LEFT
elif [ "$1" = "-r" ] ; then
   VAR="OVERSCAN_RIGHT"
   VAL=$OVERSCAN_RIGHT
elif [ "$1" = "-t" ] ; then
   VAR="OVERSCAN_TOP"
   VAL=$OVERSCAN_TOP
elif [ "$1" = "-b" ] ; then
   VAR="OVERSCAN_BOTTOM"
   VAL=$OVERSCAN_BOTTOM
fi
if [ "$VAL" != "" ] ; then
   NVAL=$(($VAL + $2))
   [ $NVAL -lt 0 ] && NVAL=0
   [ $NVAL -gt 200 ] && NVAL=200
   $SETVAL $VAR $NVAL
   source /etc/vdr.d/conf/vdr
fi
logger -s "Setting padding <$OVERSCAN_LEFT $OVERSCAN_TOP $OVERSCAN_RIGHT $OVERSCAN_BOTTOM>"
[ "$(pidof ratpoison)" != "" ] && ratpoison -c "set padding $OVERSCAN_LEFT $OVERSCAN_TOP $OVERSCAN_RIGHT $OVERSCAN_BOTTOM"
