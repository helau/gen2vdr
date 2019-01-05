#!/bin/bash
SRC_DIR=/etc/vdr/channels
TMPFILE=/tmp/cud.tmp

if [ "$(pidof vdr)" != "" ] ; then
   echo "VDR muss vor Ausfuehren des Scriptes beendet werden"
   echo "  z.B. mit /etc/init.d/vdr stop"
   exit
fi

cd "$SRC_DIR"

VDR_CONF_DIR=$(pkg-config --variable=configdir vdr)
if [ "$VDR_CONF_DIR" == "" ] ; then
   VDR_CONF_DIR="/etc/vdr"
else
   VDR_CONF_DIR=${VDR_CONF_DIR%/}
fi

SCR_CONF=${VDR_CONF_DIR}/scr.conf
DIS_CONF=${VDR_CONF_DIR}/diseqc.conf
CHAN_CONF=${VDR_CONF_DIR}/channels.conf

[ "$EDITOR" == "" ] && EDITOR=$(which nano)
[ "$EDITOR" == "" ] && EDITOR=$(which mcedit)
[ "$EDITOR" == "" ] && EDITOR=$(which vi)

#dialog_geometry() {
#   SSIZE=$(stty size)
#   ROWS=${SSIZE%% *}
#   COLS=${SSIZE##* }
#   if [ ${ROWS} -lt 24 -o ${COLS} -lt 78 ] ; then
#      echo $"Your display size <$SSIZE> is too small to run this script!"
#      echo $"It must be at least 24 lines by 78 columns!"
#      exit 1
#  fi
#}


do_unicable() {
   rm /tmp/ip*.tmp
   NUM=5
   OTHER=0
   MANU=""
   MODEL=""
   cd "${SRC_DIR}/Unicable"
   echo -n "Manuell '' 'Kein unicable' '' " >/tmp/ip1.tmp
   for i in * ; do
      [ ! -d "$i" ] && continue
      if [ "$(ls "$i/"* 2>/dev/null)" != "" ] ; then
         NUM=$((NUM+1))
         if [ "$i" != "Other" ] ; then
            echo -n "$i '' " >> /tmp/ip1.tmp
         else
            OTHER=1
         fi
      fi
   done
   [ "$OTHER" == "1" ] && echo -n "Sonstige '' " >>/tmp/ip1.tmp
   echo -n "dialog --menu 'Unicable Hersteller' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
   cat /tmp/ip1.tmp >> /tmp/ip.tmp
   echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
   echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
   echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
   echo "fi" >>/tmp/ip.tmp
   clear
   rm -f /tmp/menu.tmp
   bash /tmp/ip.tmp
   if [ -s /tmp/menu.tmp ] ; then
      MANU=$(cat /tmp/menu.tmp)
      logger -s "Hersteller: <$MANU>"
   fi
   [ "$MANU" == "" ] && return
   [ "$MANU" == "Sonstige" ] && MANU=Other
   if [ "$MANU" == "Kein unicable" ] ; then
      rm $SCR_CONF
      return
   fi
   rm /tmp/ip*.tmp
   if [ "$MANU" != "Manuell" ] ; then
      NUM=4
      for i in ${MANU}/* ; do
         if [ -s "$i" ] ; then
            NUM=$((NUM+1))
            echo -n "${i#*/} '' " >> /tmp/ip1.tmp
         fi
      done
      echo -n "Manuell ''" >>/tmp/ip1.tmp
      echo -n "dialog --menu '$MANU Modell' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
      cat /tmp/ip1.tmp >> /tmp/ip.tmp
      echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
      echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
      echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
      echo "fi" >>/tmp/ip.tmp
      clear
      rm -f /tmp/menu.tmp
      bash /tmp/ip.tmp
      if [ -s /tmp/menu.tmp ] ; then
         MODEL=$(cat /tmp/menu.tmp)
         logger -s "Model: <$MANU - $MODEL>"
      fi
      [ "$MODEL" == "" ] && return
      if [ "$MODEL" == "Manuell" ] ; then
         MANU="Manuell"
      else
         cat "${SRC_DIR}/scr.conf.sample" > $SCR_CONF
         echo -e "\n#\n# Model: $MANU - $MODEL\n#" >> $SCR_CONF
         cat "${MANU}/${MODEL}" >> $SCR_CONF
      fi
   fi
   [ ! -e $SCR_CONF ] && cp "${SRC_DIR}/scr.conf.sample" $SCR_CONF
   $EDITOR $SCR_CONF
}


do_diseqc() {
   rm /tmp/ip*.tmp
   NUM=5
   OTHER=0
   DIS=""
   cd "${SRC_DIR}/Diseqc"
   echo -n "Manuell '' 'Kein DiSEqC' '' " >/tmp/ip1.tmp
   for i in * ; do
      [ ! -s "$i" ] && continue
      NUM=$((NUM+1))
      echo -n "$i '' " >> /tmp/ip1.tmp
   done
   echo -n "dialog --menu 'DiSEqC Konfiguration' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
   cat /tmp/ip1.tmp >> /tmp/ip.tmp
   echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
   echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
   echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
   echo "fi" >>/tmp/ip.tmp
   clear
   rm -f /tmp/menu.tmp
   bash /tmp/ip.tmp
   if [ -s /tmp/menu.tmp ] ; then
      DIS=$(cat /tmp/menu.tmp)
      logger -s "DiSEqC: <$DIS>"
   fi
   [ "$DIS" == "" ] && return
   if [ "$DIS" == "Kein DiSEqC" ] ; then
      cp -f "${SRC_DIR}/diseqc.conf.sample" $DIS_CONF
      return
   fi
   rm /tmp/ip*.tmp
   if [ "$DIS" != "Manuell" ] ; then
      NUM=4
      grep "^S" /etc/vdr/sources.conf | tr -s " " > /tmp/.sources
      while read i ; do
         NUM=$((NUM+1))
         echo -n "${i%% *} '${i#* }' " >> /tmp/ip1.tmp
      done < /tmp/.sources
      echo -n "dialog --menu 'Satellit 1' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
      echo -n "Manuell '' " >>/tmp/ip.tmp
      cat /tmp/ip1.tmp >> /tmp/ip.tmp
      echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
      echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
      echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
      echo "fi" >>/tmp/ip.tmp
      clear
      rm -f /tmp/menu.tmp
      bash /tmp/ip.tmp
      if [ -s /tmp/menu.tmp ] ; then
         SAT1=$(cat /tmp/menu.tmp)
         logger -s "SAT1: <$SAT1>"
      fi
      [ "$SAT1" == "" ] && return
      if [ "$SAT1" == "Manuell" ] ; then
         DIS="Manuell"
      else
         cat $DIS | sed -e "s/^#S19.2E/${SAT1}/" > /tmp/diseqc.conf.tmp
         echo -n "dialog --menu 'Satellit 2' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
         echo -n "Manuell '' Keiner '' " >>/tmp/ip.tmp
         cat /tmp/ip1.tmp >> /tmp/ip.tmp
         echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
         echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
         echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
         echo "fi" >>/tmp/ip.tmp
         clear
         rm -f /tmp/menu.tmp
         bash /tmp/ip.tmp
         if [ -s /tmp/menu.tmp ] ; then
            SAT2=$(cat /tmp/menu.tmp)
            logger -s "SAT2: <$SAT2>"
         fi
         [ "$SAT2" == "" ] && return
         if [ "$SAT2" == "Manuell" ] ; then
            DIS="Manuell"
         else
            [ "$SAT2" != "Keiner" ] && sed -i /tmp/diseqc.conf.tmp -e "s/^#S13.0E/${SAT2}/"
            cp "${SRC_DIR}/diseqc.conf.sample" $DIS_CONF
            echo "" >> $DIS_CONF
            cat /tmp/diseqc.conf.tmp >> $DIS_CONF
         fi
      fi
   fi
   [ ! -e $DIS_CONF ] && cp "${SRC_DIR}/diseqc.conf.sample" $DIS_CONF
   $EDITOR $DIS_CONF
}


do_channels() {
   rm /tmp/ip*.tmp
   NUM=4
   OTHER=0
   TMP_CHC="/tmp/channels.conf"
   rm -f $TMP_CHC
   cd "${SRC_DIR}/Channels"
   echo -n "Manuell '' " >/tmp/ip1.tmp
   for i in * ; do
      [ ! -s "$i" ] && continue
      NUM=$((NUM+1))
      echo -n "$i '' " >> /tmp/ip1.tmp
   done
   for chc in $(seq 1 9) ; do
      echo -n "dialog --menu '${chc}. Kanalliste' $((NUM+4)) 0 $NUM " >/tmp/ip.tmp
      [ "$chc" != "1" ] && echo -n "'Keine weitere' '' " >>/tmp/ip.tmp
      cat /tmp/ip1.tmp >> /tmp/ip.tmp
      echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
      echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
      echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
      echo "fi" >>/tmp/ip.tmp
      clear
      rm -f /tmp/menu.tmp
      bash /tmp/ip.tmp
      if [ -s /tmp/menu.tmp ] ; then
         CHAN=$(cat /tmp/menu.tmp)
         logger -s "DiSEqC: <$DIS>"
      fi
      if [ "$CHAN" == "" ] ; then
         return
      elif [ "$CHAN" == "Keine weitere" ] ; then
         break
      elif [ "$CHAN" == "Manuell" ] ; then
         rm -f $TMP_CHC
         break
      else
         cat "$CHAN" >> $TMP_CHC
      fi
   done
   [ -s $TMP_CHC ] && cp $TMP_CHC $CHAN_CONF
   $EDITOR $CHAN_CONF
}

#dialog_geometry

for i in $SCR_CONF $DIS_CONF $CHAN_CONF ; do
   [ -e "$i" ] && cp -av "$i" "${i}.org"
done

bash channels_update.sh

while : ; do
   cd "${SRC_DIR}"
   dialog --menu "Receiver Konfiguration" 10 34 4 "Unicable" "" "DiSEqC" "" "Kanalliste" "" 2>$TMPFILE

   [ $? != 0 ] && break

   if [ "$(grep -i DISEQC $TMPFILE)" != "" ] ; then
      do_diseqc
   elif [ "$(grep -i UNICABLE $TMPFILE)" != "" ] ; then
      do_unicable
   elif [ "$(grep -i KANAL $TMPFILE)" != "" ] ; then
      do_channels
   fi
done
