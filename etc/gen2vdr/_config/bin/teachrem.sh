#!/bin/sh
if [ ! -f "$1" ] ; then
   echo -e "Syntax: $0 <template>\n  Erstellt anhand von <template> ein <template>.conf passend fuer inputevxd\n\n"
   exit
fi
OUTPUT="${1##*/}.conf"
if [ -e "$OUTPUT" ] ; then
   echo "Config <$OUTPUT> existiert bereits - Enter fuer ueberschreiben, Ctrl+C fuer Abbruch"
   read
   mv -f "$OUTPUT" "${OUTPUT}.bak"
fi
if [ "$(pidof vdr X)" != "" ] ; then
   echo "VDR und G2VGUI muessen beendet werden fuer $0"
   echo "Druecke Enter fuer das Beenden der Prozesse, Abbruch mit Ctrl-C"
   read
   /etc/init.d/vdr stop
   /etc/init.d/g2vgui stop
fi

echo -e "\nVerfuegbare Event Devices:\n\n"
cat /proc/bus/input/devices |grep "^[NH]"|tr -d "\n" |sed -e "s/N: Name=/\n/g" -e "s/H: Handlers=/ /g" | grep " kbd"
echo -en "\n\nGebe die Nummer des devices mit Enter ein\n\n   event"
read DN
DEV="/dev/input/event${DN}"
ALLKEYS=" "
echo -e "\nLese von device: <$DEV>\n\n"
echo -e "\nSchreibe <$2><$OUTPUT>\n\n"
cat "$1" | while read i ; do
   echo -e "\nDruecke Taste fuer <${i%%=*}>"
   KEY="$(readevent $DEV)"
   KEY="${KEY##* }"
   if [ "${ALLKEYS/* ${KEY} */}" = "" ] ; then
      LN="#${KEY} $i"
      echo "${KEY}=${i#*=}"
   else
      LN="${KEY}=${i#*=}"
      ALLKEYS="${ALLKEYS}${KEY} "
   fi
   echo "${LN}"
   echo "${LN}" >> "$OUTPUT"
   sleep 2
done
echo -e "\n Das wars :)"
echo "Sollen VDR und G2VGUI wieder gestartet werden ?"
echo "Druecke Enter fuer das Starten Prozesse, Abbruch mit Ctrl-C"
/etc/init.d/vdr start
/etc/init.d/g2vgui start
