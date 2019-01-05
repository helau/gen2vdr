#!/bin/bash
# Taken from http://wiki.easy-vdr.de/index.php/UTF8-skript
set -x

convmv -f iso-8859-15 -t utf-8 -r  /video*/  --notest
count_all_info=0
count_converted_info=0
find -L /video* -name info.vdr | while read i ; do
   ((count_all_info++))
   char_type="$(utrac -p -L DE "$i")"
   echo $char_type
   if [ "$char_type" != "UTF-8" ] && [ "$char_type" != "" ]; then
      recode $char_type..utf8 "$i"
      ((count_converted_info++))
   fi
done
echo "Von $count_all_info info.vdr sind $count_converted_info nach UTF-8 konvertiert worden."

