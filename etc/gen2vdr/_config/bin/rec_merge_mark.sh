#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ ! -s "${1%/}/index" ] ; then
   glogger "ERROR: <${1%/}/index> nicht vorhanden"
   exit
fi

rm ${VIDEO}/rec_marked > /dev/null 2>&1

# determine if is recording
newest_file="$(ls -t "$1/" | head -n 1)"
fdate="$(stat -c %Y "${1}/${newest_file}")"
act_date="$(date +%s)"

if [ $(($act_date - 10)) -ge $fdate ] ; then
   ln -s "$1" ${VIDEO}/rec_marked
   glogger "Bereit zum Zusammenfuegen: $1"
else
   glogger "ERROR: <$1> wird derzeit benutzt"
fi
