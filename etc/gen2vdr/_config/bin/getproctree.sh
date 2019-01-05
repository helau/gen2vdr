#!/bin/bash
#set -x
ALL_PIDS=" "
for i in $@ ; do
   while read j ; do
      while read k ; do
         [ "${ALL_PIDS/* $k */}" != "" ] && ALL_PIDS="${ALL_PIDS}$k "
      done < <(pstree -pal $j | grep -v "},[0-9]" | cut -f 2 -d,| cut -f 1 -d " ")
   done < <(ps -ef | tr -s " " | cut -f 2,3,8,9 -d " " | sed -e "s/$/ /" | grep " $i " | cut -f 1 -d " ")
done
echo $ALL_PIDS
