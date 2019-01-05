#!/bin/bash
source /_config/bin/g2v_funcs.sh
ls -l $VDR_EXEC
for i in /tmp/corefiles/core.* ; do 
   ls -l $i 
   gdb $VDR_EXEC $i --batch --quiet -ex "thread apply all bt full" -ex "quit"
   echo ""
   rm -f $i
done
