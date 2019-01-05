#!/bin/bash
source /_config/bin/g2v_funcs.sh
if [ -d "$1" ] ; then
   cd "$1"
else
   cd $VIDEO
fi
rm -f $(find . -follow -name "*__*.m3u" -type d) 2>/dev/null
find . -follow -name "*.rec" -type d | while read i ; do 
   FN="$(grep "^T " $i/info* |cut -f 2- -d " " |tr " " "_")"
   DT=${i##*/}
   DT="${DT%.*.*.rec}"
   DT="${DT:2}"
   DT="${DT//[-.]/}"
   FN="${FN}__${DT}.m3u"
   for j in $i/[0-9]* ; do 
      echo "$j"
   done > $i/../$FN
done
