#!/bin/bash
source /_config/bin/g2v_funcs.sh
cd /usr/local/src/

dialog_geometry() {
   ROWS="${1:-24}"
   COLS="${2:-78}"
   ROWS="${ROWS/#0/24}"
   COLS="${COLS/#0/78}"
   if [ "${ROWS}" -lt 24 -o "${COLS}" -lt 78 ] ; then
      echo $"Your display is too small to run this script!"
      echo $"It must be at least 24 lines by 78 columns!"
      echo "`stty size` (stty size) ..."
      exit 1
   else
      ROWS="$((ROWS-2))"
      COLS="$((COLS-2))"
      MSIZE="${ROWS} ${COLS} $((ROWS-6))"
   fi
   MAX_ROWS=$ROWS
   MAX_COLS=$COLS
}
SAVE_CHANGES=0
dialog_geometry `stty size 2>/dev/null`

ACT_REV="$(readlink VDR)"
ACT_REV="${ACT_REV%/}"
ALL_REVS="${ACT_REV%/}"
NEW_REV=""

echo "dialog --backtitle \"VDR Bauprozess\" --title \"VDR Version waehlen\" --menu \"\" \\" > /tmp/ip.tmp
NP=1
if [ "$ACT_REV" != "" ] ; then
   echo -n "\"${ACT_REV}\" \"Aktiv\" " > /tmp/ip.tmp1
   NP=1
else
   rm -f /tmp/ip.tmp1
   NP=0
fi
for i in vdr-[0-9].*/Make.config ; do
   if [ "${i%%/*}" != "${ACT_REV%/}" ] ; then
      ALL_REVS="$ALL_REVS ${i%%/*}"
      echo -n "\"${i%%/*}\" \"\" " >> /tmp/ip.tmp1
      NP=$(($NP+1))
   fi
done

if [ $NP -gt 1 ] ; then
   echo "$(($NP + 6)) 38 $NP \\" >> /tmp/ip.tmp
   cat /tmp/ip.tmp1 >> /tmp/ip.tmp
   echo " 2>/tmp/menu.tmp" >>/tmp/ip.tmp
   echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
   echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
   echo "fi" >>/tmp/ip.tmp
   clear
   rm -f /tmp/menu.tmp
   bash /tmp/ip.tmp
   if [ -s /tmp/menu.tmp ] ; then
      PN=$(cat /tmp/menu.tmp)
      NEW_REV=$PN
   fi
fi
clear
if [ "$NEW_REV" != "" ] ; then
   cnt=0
   SUBMENU="lxdialog --title 'Waehle Patches' --menu '' ${MSIZE} \"\${subchoice}\" "
   while read i ; do
      var[${cnt}]=${i##*DUSE_}
      SPN="${var[${cnt}]}                                  "
      sed -i ${NEW_REV}/Make.config -e "s/^[ ]*${var[$cnt]}/${var[$cnt]}/"
      if [ "$(grep "^${var[${cnt}]} = 1" ${NEW_REV}/Make.config)" != "" ] ; then
         val[${cnt}]="Ein"
      else
         val[${cnt}]="Aus"
      fi
      SUBMENU="$SUBMENU $cnt \"${SPN:0:25}  < ${val[$cnt]} >\" "
      cnt=$((cnt+1))
   done < <(grep "DEFINES += -DUSE_" ${NEW_REV}/Make.config)
   while : ; do
      #glogger "${SUBMENU}"
      #glogger "SC<$subchoice>"
      { subchoice=`eval "${SUBMENU}" 2>&1 >&3 3>&-`; } 3>&1
      subrc=$?
      #glogger "Sub RC: $subrc <$subchoice>"
      case $subrc in
         0|3|4|5|6)
            #glogger "Value: <${val[$subchoice]}>"
            if [ "${val[${subchoice}]}" = "Ein" ] ; then
               val[${subchoice}]="Aus"
            else
               val[${subchoice}]="Ein"
            fi
            ;;
         1) break
            ;;
         2) subchoice=${subchoice%% *}
            ;;
      esac
      SUBMENU="lxdialog --title 'Waehle Patches' --menu '' ${MSIZE} \"\${subchoice}\" "
      for i in $(seq 0 $((cnt - 1))) ; do
         SPN="${var[${i}]}                                  "
         SUBMENU="$SUBMENU $i \"${SPN:0:25}  < ${val[$i]} >\" "
      done
      subchoice=${subchoice%% *}
   done
   clear
   echo "VDR <$ACT_REV> wird gebaut, Weiter mit Enter, Abbruch mit Strg-C (Ctrl-C)"
   read i
   rm VDR
   ln -s $NEW_REV VDR
   #set -x
   glogger "VDR <$ACT_REV> wird gebaut ..."
   cd VDR
   cp Make.config Make.config.org
   for i in $(seq 0 $((cnt - 1))) ; do
      if [ "${val[${i}]}" = "Ein" ] ; then
         sed -i Make.config -e "s/#[ ]*${var[$i]}/#${var[$i]}/" -e "s/#${var[$i]} =.*/${var[$i]} = 1/"
      else
         sed -i Make.config -e "s/^[ ]*${var[$i]}/${var[$i]}/" -e "s/^${var[$i]} =.*/#${var[$i]} = 1/"
      fi
   done
   cpu_num=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
   make -j $((cpu_num+1)) clean clean-plugins
   make -j $((cpu_num+1))
   echo ""
   if [ "$?" != "0" ] ; then
      glogger -s "Fehler beim Kompilieren des VDR"
   else
      echo -e "\n\nPlugins werden gebaut ...\n\n"
      make -j $((cpu_num+1)) plugins
      echo -e "\n\nSoll die neu gebaute Version aktiviert werden ?\nWeiter mit Enter - Abbruch mit Strg-C (Ctrl-C)"
      read i
      /etc/init.d/vdr stop
      /etc/init.d/g2vgui stop
      /_config/bin/instvdr.sh
      /etc/init.d/vdr start
      /etc/init.d/g2vgui start
   fi
else
   glogger -s "Keine VDR-Version ausgewaehlt"
fi
