#!/bin/bash
#set -x
echo ""
if [ "$1" = "-v" ] ; then
   ONLY_SUM=0
   PKG=$2
else   
   ONLY_SUM=1
   PKG=$1
fi

if [ "$(echo $PKG | grep "/")" != "" ] ; then
   GROUP=$(echo $PKG | cut -f 1 -d "/")
   PKG=$(echo $PKG | cut -f 2 -d "/")
else
   GROUP="*"   
fi
ALL_PKG=$(ls /var/db/pkg/$GROUP/$PKG-[0-9].* | grep "^/var" | cut -f 1 -d ":")
[ "$ALL_PKG" = "" ] && ALL_PKG=/var/db/pkg/$GROUP/$PKG-[0-9].*
sum=0
for i in $ALL_PKG ; do
   ts=0
   [ "$ONLY_SUM" = "1" ] && echo "Checking $i ..."    
   for j in $(cat $i/CONTENTS |grep "^obj" |cut -f 2 -d " ") ; do 
      ps=$(stat -c%s "$j")
      ts=$(($ps+$ts))
      [ "$ONLY_SUM" = "0" ] && echo "$ps $j" 
   done
   echo "Size: $ts - $i"
   echo ""
   sum=$(($sum+$ts))
done   
echo "Total Size: $sum"
