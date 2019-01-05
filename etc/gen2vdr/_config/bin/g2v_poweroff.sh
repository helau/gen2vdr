#!/bin/bash
source /_config/bin/g2v_funcs.sh
if [ "$AFP_WATCHDOG" != "" -a "$AFP_WATCHDOG" != "0"  ] ; then
   /usr/bin/afp-tool -h $(($AFP_WATCHDOG + 10)) > /dev/null 2>&1
fi
/_config/bin/g2v_fsck.sh
