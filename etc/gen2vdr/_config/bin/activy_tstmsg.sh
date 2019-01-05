#!/bin/bash
# Activy set Display text
#/bin/stty 38400 < /dev/ttyS0
for i in 2 3 4 5 6 7 8 9 0 a b c d e f ; do 
   str=""
   for j in 0 1 2 3 4 5 6 7 8 9 0 a b c d e f; do 
      str="$str\x$i$j"
   done
   xStr="$(printf "$str")"
   printf "$i $xStr\x00" > /dev/ttyS0
   sleep 5
done
#printf "\x9A\x02$1\x00" > /dev/ttyS0
#printf "\x9A\x03$2\x00" > /dev/ttyS0
#printf "\xF0\x3D" > /dev/ttyS0