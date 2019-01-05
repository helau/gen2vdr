#!/bin/sh
#set -x
PORT="/usr/local/portage"
cd $PORT
find . -name "*.ebuild" |cut -f 2- -d "/" | while read i  ; do
   fn=${i%.ebuild}
   fn=${fn##*/}
   if [ "$(diff -uN $i /var/db/pkg/${i%%/*}/$fn/$fn.ebuild)" = "" ] ; then
      echo "Used: $i"
   else
      echo "Unused: $i"
   fi
done

