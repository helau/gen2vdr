#!/bin/bash
function frm2mark {
   frm=$(($1 - 1))
   printf "%d:%02d:%02d.%02d\n" $(($frm / 60 / 60 / 25)) $((($frm % 90000) / 60 / 25)) $((($frm % 1500) / 25)) $((($frm % 25) + 1))
}

if [ "$1" != "" ] && [ -d "$1" ] ; then
   cd "$1"
fi
if [ ! -e index ] ; then
   echo "index not found"
   exit
fi
oldflnum=""
oldfrmnum=""
hexdump -C index| cut -f 2- -d " " | sed -e "s/  |.*//" -e "s/  /\n /" | grep -n -e "01 .. 00 00$" > /tmp/idx.marks
while read i ; do
   frmnum=${i%%:*}
   ln=${i#*: }
   if [ "${ln:15:2}" != "$oldflnum" ] ; then
      [ "$oldfrmnum" != "" ] && frm2mark $oldfrmnum
      frm2mark $frmnum
      oldflnum="${ln:15:2}"
   fi
   oldfrmnum=$frmnum
   export oldfrmnum
done < /tmp/idx.marks
frm2mark $oldfrmnum
