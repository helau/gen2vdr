#!/bin/bash
source /_config/bin/g2v_funcs.sh

AR=$(xrandr |grep "*"|tr -s " " | cut -f 3- -d " ")
def=${AR%% *}
act=${AR%%\* *}
act=${act##* }
if [ "$act" != "$def" ] ; then
   glogger -s "Setting refresh rate to $def"
   xrandr -r $def |logger
else
   glogger -s "Refresh already at $def"
fi
