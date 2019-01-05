#!/bin/bash
# ---
# copy2usb.sh
# Wird aufgerufen, wenn man im VDR Aufnahmen auf USB kopiert
# ---

# VERSION=170214

source /_config/bin/g2v_funcs.sh
# set -x
CP2USB='/tmp/~cp2usb.sh'  # Temporäres Skript

TARGET=$(mount | grep -m 1 " /media/" | cut -f 3 -d " ")
if [[ -n "$TARGET" && -d "$TARGET" && -n "$1" && -d "$1" ]] ; then
   TD="${1%/*}"  # "$(dirname "$1")"
   glogger -s "Kopiere $1 nach $TARGET ..."
   { echo '#!/bin/bash'
     echo "mkdir -p \"${TARGET}${TD}\""
     echo "svdrpsend.sh MESG \"Video wird nach ${TARGET}${TD} kopiert ...\""
     echo "if cp -rvf \"$1\" \"${TARGET}${TD}\" ; then"
     echo "  svdrpsend.sh MESG \"Video wurde nach ${TARGET}${TD} kopiert\""
     echo 'else'
     echo "  svdrpsend.sh MESG \"FEHLER beim kopieren von $1\""
     echo 'fi'
     echo "/_config/bin/linkvid.sh ${TARGET}/video"  # Aufnahmeliste im VDR aktualisieren
   } > "$CP2USB"
   screen -dm sh -c "sh $CP2USB"  # Temporäres Skript starten
else
   glogger -s "$0: Illegal parameter <$1> or no usb drive found"
fi
