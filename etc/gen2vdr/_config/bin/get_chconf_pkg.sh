#!/bin/bash
URL="http://www.vdr-wiki.de"

function conv_chan() {
   FOUND=0
   NAME="$1"
   echo "Checking $1 ..."
   while read i ; do
      if [ "$FOUND" = "0" ] ; then
         if [ "${i#*\<h1 id=}" != "$i" ] ; then
            echo "$i"
            NM="${i#*\>}"
            NM=${NM%\<*}
            NM=${NM#* }
            NM=${NM// /-}
            NM="${NM//\//-}"
         fi
         if [ "${i/<pre>/}" != "$i" ] ; then
            FOUND=1
            i=${i#*<pre>}
         fi
         [ -f "cc.$NM" ]&& rm "cc.$NM"
      fi
      if [ "$FOUND" = "1" ] ; then
         if [ "${i/<\/pre>/}" != "$i" ] ; then
            FOUND=0
            i=${i%</pre>*}
         fi
         if [ "${i// /}" != "" ] ; then
            ln=${i//&amp;/&}
            ln=${ln//&nbsp;/ }
            echo "$ln" >> "cc.$NM"
         fi
         [ "$FOUND" = "0" ] && break
      fi
   done < <(cat "$NAME")
   cat "cc.$NM" | recode utf-8..latin1 > "channels.conf.$NM"
}

# get channels.conf from vdr-wiki
for i in S C T ; do
   wget -O - "$URL/wiki/index.php/DVB-${i}_channels.conf" 2>/dev/null | grep "Channels.conf.DVB${i}" | sed -e "s#a href=\"/wiki#a\nhref=\"/wiki#g" | grep "php/Channels.conf.DVB${i}" | cut -f 2,4 -d '"' | grep -v "TEMPLATE" | while read chan ; do
      chan=${chan#/}
      LNK="$URL/${chan%\"*}"
      NAME="${chan#*\"}"
      NAME="${NAME//\//-}"
      CC="channels.conf.html.${NAME#Channels.conf }"
      wget -O - "$LNK" 2>/dev/null > "$CC"
      conv_chan "$CC"
      rm "$CC"
   done
done

# get channels.conf from linowsat
URL="http://www.linowsat.de/settings/vdr"
wget -O channels.conf.DVBS-S19.2-Astra-FTA-Linowsat "$URL/0192/fta/channels.conf"
wget -O channels.conf.DVBS-S19.2-Astra-All-Linowsat "$URL/0192/ca/channels.conf"
wget -O channels.conf.DVBS-S19.2S13-Astra-Hotbird-FTA-Linowsat "$URL/01300192/fta/channels.conf"
wget -O channels.conf.DVBS-S19.2S13-Astra-Hotbird-All-Linowsat "$URL/01300192/ca/channels.conf"
wget -O channels.conf.DVBS-S19.2S13S28-Astra12-Hotbird-FTA-Linowsat "$URL/013001920282/fta/channels.conf"
wget -O channels.conf.DVBS-S19.2S13S28-Astra12-Hotbird-All-Linowsat "$URL/013001920282/ca/channels.conf"
dos2unix chan*
sed -i channels.co* -e "/^$/d"
