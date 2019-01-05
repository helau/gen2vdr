#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ "$1" = "" ] || [ ! -f $1 ] ; then
   glogger -s "$1 nicht vorhanden"
fi
Newline=$'\n'
IFS="${Newline}"

for i in $(grep "^[A-Z]" "$1") ; do
   VAR="$(echo "$i" | cut -f 1 -d "=")"
   VAL="$(echo "$i" | cut -f 2 -d "\"")"
   if [ "$VAR" != "" -a "$VAL" != "" ] ; then
      $SETVAL $VAR "$VAL"
   fi      
done