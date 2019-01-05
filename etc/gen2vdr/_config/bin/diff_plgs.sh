#!/bin/bash
cat $1 | while read i ; do 
   echo $i
   if [ "${i:0:1}" = "P" ] ; then
      PLG=$(echo ${i##* } | tr "[:upper:]" "[:lower:]")
      readlink /usr/local/src/VDR/PLUGINS/src/$PLG
      ls -d /usr/local/src/VDR/PLUGINS/src/${PLG}-*
   fi
done
