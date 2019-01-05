#!/bin/bash
if [ -s "$1" ] ; then
   cd Unicable
   cat "../$1" | while read ln ; do
      if [ "${ln/<OutdoorUnit/}" != "$ln" ] ; then
         NAME=$(echo "$ln" | cut -f 2 -d '"' | tr "/" "_")
         NAME="${NAME// /_}"
         [ "${ln/*Manufacturer=*/}" == "" ] && MANU=$(echo "$ln" | cut -f 4 -d '"')
         [ "${ln/*Type=*/}" == "" ]         && TYPE=$(echo "$ln" | cut -f 6 -d '"')
         MANU="${MANU// /_}"
         [ "$MANU" == "" ] && MANU="Other"
         [ ! -d "$MANU" ] && mkdir "$MANU"
         NUM=0
         rm -f "${MANU}/${NAME}"
      elif [ "${ln/<UBSlot Freq/}" != "$ln" ] ; then
         FREQ=$(echo "$ln" | cut -f 2 -d '"')
         echo "$NUM $FREQ" >> "${MANU}/${NAME}"
         NUM=$((NUM+1))
      elif [ "${ln/</OutdoorUnit/}" != "$ln" ] ; then
         NAME=""
         MANU=""
         TYPE=""
         NUM=0
      fi
   done
   cd ..
else
   echo "<$1> not found"
fi
