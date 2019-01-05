#!/bin/bash
source /_config/bin/g2v_funcs.sh
export LANGUAGE=en_US.UTF-8
aplay -l > /tmp/~aplay.out
ALL_DEV=""

grep "^card .*, device " /tmp/~aplay.out | while read i ; do 
   ln=${i#* }
   CNum=${ln%%: *}
   ln=${ln#* }
   CName=${ln%% [*}
   ln=${ln#*, device }
   DNum=${ln%%: *}
   ln=${ln#* }
   DName=${ln%% [*}
   DESC="${CName} : ${DName}"
   echo "\"$CNum:$DNum\" \"[${CName} : ${DName}]\" \\"
done > /tmp/~asnd.cfg

rm -rf /tmp/ip.* /tmp/.ac* > /dev/null 2>&1
def_item=1
count=0
for DEV in ANALOG SPDIF HDMI ; do
   DI="$(cat /tmp/~asnd.cfg | head -n $def_item | tail -n 1|  cut -f 2 -d '"')"
   echo "dialog --title \"${DEV}-Device waehlen\" --menu \"\" 0 0 0 \\" > /tmp/ip.tmp
   [ -s /tmp/~asnd.cfg ] && cat /tmp/~asnd.cfg >> /tmp/ip.tmp
   echo "\"\" \"Keines\" 2>/tmp/menu.tmp" >>/tmp/ip.tmp
   echo "if [ \"\$?\" != \"0\" ] ; then" >>/tmp/ip.tmp
   echo "   rm -f /tmp/menu.tmp" >>/tmp/ip.tmp
   echo "fi" >>/tmp/ip.tmp

   clear
   rm -f /tmp/menu.tmp
   bash /tmp/ip.tmp
   if [ -s /tmp/menu.tmp ] ; then
      PN=$(cat /tmp/menu.tmp)
      glogger -s "$DEV : <$PN>"
      echo "$DEV=\"$PN\"" >> /tmp/.ac
      def_item=$((def_item + 1))
      count=$((count + 1))
      sed -i /tmp/~asnd.cfg -e "/.*${PN}.*/d"
   fi
done
source /tmp/.ac
CARD=""
ND="a"
NN=0
[ -e /etc/asound.conf ] && mv -f /etc/asound.conf /etc/asound.conf.bak
if [ $count -gt 1 ] ; then
   echo -e "pcm.!default {\n  type plug\n  slave.pcm \"multi\"\n" > /etc/asound.conf
   for i in 0.0 1.1 0.2 1.3 0.4 1.5 ; do
      echo "  ttable.$i 1.0" >> /etc/asound.conf
   done
   echo -e "}\n" >> /etc/asound.conf
   if [ "$HDMI" != "" ] ; then
      echo -e "\npcm.hdmiout {\n  type hw\n  card ${HDMI%:*}\n  device ${HDMI#*:}\n}" >> /etc/asound.conf
      echo -e "\nctl.hdmiout {\n  type hw\n  card ${HDMI%:*}\n  device ${HDMI#*:}\n}" >> /etc/asound.conf
      echo -e "  slaves.${ND}.pcm \"hdmiout\"\n  slaves.${ND}.channels 2" >> /tmp/.acm

      echo -e "\n  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 0" >> /tmp/.acm2
      NN=$((NN + 1))
      echo -e "  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 1" >> /tmp/.acm2
      NN=$((NN + 1))
      ND="b"
      CARD=${HDMI%:*}
   fi
   if [ "$SPDIF" != "" ] ; then
      echo -e "\npcm.digital {\n  type hw\n  card ${SPDIF%:*}\n  device ${SPDIF#*:}\n}" >> /etc/asound.conf
      echo -e "\nctl.digital {\n  type hw\n  card ${SPDIF%:*}\n  device ${SPDIF#*:}\n}" >> /etc/asound.conf
      echo -e "\n  slaves.${ND}.pcm \"digital\"\n  slaves.${ND}.channels 2" >> /tmp/.acm

      echo -e "\n  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 0" >> /tmp/.acm2
      NN=$((NN + 1))
      echo -e "  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 1" >> /tmp/.acm2
      NN=$((NN + 1))
      if [ "$ND" = "a" ] ; then
         ND="b"
      else
         ND="c"
      fi
      CARD=${SPDIF%:*}
   fi
   if [ "$ANALOG" != "" ] ; then
      echo -e "\npcm.analog {\n  type hw\n  card ${ANALOG%:*}\n  device ${ANALOG#*:}\n}" >> /etc/asound.conf
      echo -e "\nctl.analog {\n  type hw\n  card ${ANALOG%:*}\n  device ${ANALOG#*:}\n}" >> /etc/asound.conf
      echo -e "\n  slaves.${ND}.pcm \"analog\"\n  slaves.${ND}.channels 2" >> /tmp/.acm

      echo -e "\n  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 0" >> /tmp/.acm2
      NN=$((NN + 1))
      echo -e "  bindings.${NN}.slave ${ND}\n  bindings.${NN}.channel 1" >> /tmp/.acm2
      CARD=${ANALOG%:*}
   fi
   echo -e "\npcm.multi {\n  type multi\n" >> /etc/asound.conf
   cat /tmp/.acm /tmp/.acm2 >> /etc/asound.conf
   echo -e "}\n\nctl.multi {\n  type hw\n  card $CARD\n}" >> /etc/asound.conf
elif [ $count -eq 1 ] ; then
   DEV="${HDMI}${SPDIF}${ANALOG}"
   echo -e "pcm.!default {\n  type hw\n  card ${DEV%:*}\n  device ${DEV#*:}\n}" > /etc/asound.conf
else
   echo "Kein device angegeben !"
fi
if [ -e /etc/asound.conf ] ; then
   echo "/etc/asound.conf wurde erstellt"
   sed -i /root/.xine/config /root/.xine/config_xineliboutput \
       -e "s/^\(audio.device.alsa_.*_device:.*\)/# \1/"
fi
