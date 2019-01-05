#!/bin/bash
source /_config/bin/g2v_funcs.sh

cd $VIDEO
DEL_RECS=$(find . -follow -type d -name "*.del" -print -prune -o -follow -type d -name "*.rec" -prune 2>/dev/null)

for i in $DEL_RECS ; do
   echo "Deleting ${i} ..."
   rm -rf ${i}
done

ALL_DIRS=$(find . -follow -type d -name "*" -print -prune -o -follow -type d -name "*.rec" -prune 2>/dev/null)

for i in $ALL_DIRS ; do
   contents=$(ls ${i})
   if [ "$contents" = "" ] ; then
      echo "Deleting ${i}"
      rmdir ${i}
   fi
done
