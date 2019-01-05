#!/bin/bash
source /_config/bin/g2v_funcs.sh
growisofs -dvd-compat -use-the-force-luke=tty -speed=4 -Z "/dev/cdrom=$1"
if [ "$?" = "0" ] ; then
   glogger -s "$1 wurde erfolgreich gebrannt"
   svdrps MESG "$1 wurde erfolgreich gebrannt"
else
   glogger -s "Fehler beim Brennen von $1"
   svdrps MESG "Fehler beim Brennen von $1"
fi
