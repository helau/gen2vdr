#!/bin/bash
source /_config/bin/g2v_funcs.sh

DEL_RECS=$(find $VIDEO -follow -type d -name "*.del" -print -prune -o -follow -type d -name "*.rec" -prune 2>/dev/null)
if [ "$DEL_RECS" = "" ] ; then
   echo "Keine geloeschten Aufzeichnungen gefunden"
else
   for i in $DEL_RECS ; do
      glogger -s "Undeleting ${i} ..."
      mv "${i}" "${i/.del/.rec}"
   done
fi
