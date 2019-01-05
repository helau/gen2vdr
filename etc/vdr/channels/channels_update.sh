#!/bin/bash
SRV="channelpedia.yavdr.com"
ping -c1 -i1 -W3 $SRV > /dev/null 2>&1
[ "$?" != "0" ] && echo "Kann $SRV nicht erreichen" && exit

URL="http://${SRV}/gen"
[ ! -d Channels ] && mkdir Channels

act_date=$(date +%s)
if [ "$1" != "-f" ] && [ -s Channels/.updated ] ; then
   old_date=$(cat Channels/.updated)
   if [ $((act_date-old_date)) -lt 3600 ] ; then
      echo "Kanalliste ist aktuell - force Update with Parameter -f"
      exit
   fi
fi
echo "$act_date" > Channels/.updated

echo "Hole aktuelle Kanallisten von channelpedia ..."
wget -q -O - "${URL}/index.html" | grep "<li><a href=\"./DVB-" | while read i ; do
   ln=${i#*DVB-}
   [ "${ln:0:1}" == "S" ] && TYP="Sat"
   [ "${ln:0:1}" == "C" ] && TYP="Kabel"
   [ "${ln:0:1}" == "T" ] && TYP="Terr"
   NAME="${ln%%</b>*}"
   NAME="${NAME##*>}"
   NAME="${NAME# }"
   LN="${ln%%/\"*}"
   LINK="./DVB-${LN}/"
   if [ "${ln:0:1}" == "S" ] ; then
#   http://channelpedia.yavdr.com/gen/DVB-S/S1W/S1W_complete_sorted_by_groups.channels.conf
      TYP="Sat"
      LINK="DVB-${LN}/${LN#S/}_complete_sorted_by_groups.channels.conf"
   elif [ "${ln:0:1}" == "C" ] ; then
#   http://channelpedia.yavdr.com/gen/DVB-C/at/salzburg-ag/Saalfelden/C[at_salzburg-ag_Saalfelden]_complete.channels.conf
      TYP="Kabel"
      LN2="${LN#C/}"
      LINK="DVB-${LN}/C[${LN2//\//_}]_complete_sorted_by_groups.channels.conf"
   elif  [ "${ln:0:1}" == "T" ] ; then
#   http://channelpedia.yavdr.com/gen/DVB-T/at/Linz/T[at_Linz]_complete.channels.conf
      TYP="Terr"
      LN2="${LN#T/}"
      LINK="DVB-${LN}/T[${LN2//\//_}]_complete_sorted_by_groups.channels.conf"
   fi
   wget -q -O "Channels/DVB${ln:0:1}_${NAME// /_}" ${URL}/${LINK}
   echo "$TYP - $NAME"
done
