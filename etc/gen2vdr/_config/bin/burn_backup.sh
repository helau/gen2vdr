#!/bin/bash
source /_config/bin/g2v_funcs.sh

ISO="$(ls /mnt/data/backup/g2v*.iso | tail -n 1)"
if [ "$1" != "" -a -f "$1" ] ; then
   ISO=$1
fi
if [ -f "$ISO" ] ; then
#   dvd+rw-format /dev/cdrom
   growisofs -dvd-compat -use-the-force-luke=tty -speed=4 -Z /dev/cdrom=$ISO
   svdrps "MESG VDR Backup (DVD) wurde gebrannt"
else
   svdrps "MESG ISO $ISO nicht vorhanden"
fi
