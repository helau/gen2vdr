#!/bin/bash
source /_config/bin/g2v_funcs.sh

svdrps MESG "Umwandlung der Audio-CD ist gestartet"
rm -f /tmp/create-new
mp3c -i /_config/bin/.mp3crc -b /tmp/create-new
/tmp/create-new -3 -v
rm /tmp/create-new
eject /dev/cdrom
svdrps MESG "Audio-CD Umwandlung beendet"

