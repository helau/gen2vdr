#!/bin/bash
source /_config/bin/g2v_funcs.sh

X_CFG="/etc/X11/xorg.conf"
export PATH="/opt/bin:$PATH"

function set_softhd {
   if [ "$1" == "VPP" ] ; then
      PLG_DIR=softhddevice-vpp-git
   else
      PLG_DIR=softhddevice-openglosd-git
   fi
   glogger -s "Setting softhddevice to $PLG_DIR"
   sed -i ${VDR_SOURCE_DIR}/Make.plgcfg -e "s%OPENGLOSD = .%OPENGLOSD = ${OGL}%"
   cd ${VDR_SOURCE_DIR}/PLUGINS/src
   if [ "$(readlink softhddevice)" != "${PLG_DIR}" ] ; then
      rm softhddevice
      ln -s ${PLG_DIR} softhddevice
      cd softhddevice
      make all
      make install
   fi
}

function clean_xorg {
   SECTION="blabla"
   LASTLINE="blabla"
   DUPL=""
   DELDUP_SECTS=" Screen Device Monitor "
   DEL_SECTS=" Files "
   oldifs="$IFS" #Saves the old value
   IFS="" #Set it to NULL. Prevents "read" from ignoring spaces
   while read line ; do
      if [ "$line" != "" ] ;  then
         if [ "${line%%Section*}" = "" ] ; then
            NEW_SECTION="${line#*\"}"
            NEW_SECTION="${NEW_SECTION%%\"*}"
           # echo "Section: <${NEW_SECTION}>"
            if [ "$NEW_SECTION" = "$SECTION" ] ; then
               [ "${DELDUP_SECTS/* $SECTION *}" = "" ] && DUPL="1"
            elif [ "${DEL_SECTS/* $NEW_SECTION *}" = "" ] ; then
               DUPL="1"
            elif [ "$NEW_SECTION" != "" ] ; then
               SECTION=${NEW_SECTION}
               DUPL=""
            fi
         elif [ "${line%%EndSection*}" = "" ] ; then
            if [ "$DUPL" = "1" ] ; then
               DUPL=""
               line=""
            fi
         fi
      fi
      if [ "$DUPL" = "" ] ; then
         if [ "${line}${LASTLINE}" != "" ] ; then
            if [ "${line}" = "" ] || [ "${line/*Screen1*/}" != "" -a "${line/*Screen2*/}" != "" ] ; then
               echo "$line"
               LASTLINE="$line"
            fi
         fi
      fi
      #echo "$line"
   done < $1
   IFS="$oldifs"
}
#set -x
echo "Setting xorg.conf"

if [ "$(lspci | grep -i "VirtualBox Graphics Adapter")" != "" ] ; then
   cp /etc/X11/xorg.conf /etc/X11/xorg.conf.virtualbox
   $SETVAL -x PLG_xineliboutput 99
   $SETVAL -x PLG_skinnopacity 98
   $SETVAL -x PLG_skindesigner 96
   $SETVAL -x PLG_tvguideng 97
   $SETVAL -x PLG_tvguide 0
   $SETVAL -x PLG_softhddevice 0
   sed -i /etc/vdr/setup.conf -e "s/OSDSkin = .*/OSDSkin = estuary4vdr/"
   eselect opengl set xorg-x11
   exit
fi

if [ "$(pidof X)" != "" ] ; then
   /_config/bin/gui_stop.sh
   /_config/bin/killX.sh
fi
rm /root/xorg.conf.new /xorg.conf.new > /dev/null 2>&1
X -configure
[ -e $X_CFG ] && mv $X_CFG $X_CFG.bkp
[ -e /root/xorg.conf.new ] && clean_xorg /root/xorg.conf.new > $X_CFG
[ -e /xorg.conf.new ] && clean_xorg /xorg.conf.new > $X_CFG

# Remove sessions
#sed -i $X_CFG -e "s/\(.*Screen.*\"Screen[1-9].*\)/#\1/"

# if fbdev or vboxvideo is detected use vesa
sed -i $X_CFG -e "s/\(.*\)Driver\(.*\)fbdev/\1Driver\2vesa/" -e "s/\(.*\)Driver\(.*\)vboxvideo/\1Driver\2vesa/"

# set Fontpath
#sed -i $X_CFG -e "/\tFontPath/d"
#for i in /usr/share/fonts/*/fonts.dir ; do
#   if [ $(cat $i|wc -l) -gt 1 ] ; then
#      FP=${i%/*}
#      sed -i $X_CFG -e "s%\(.*ModulePath.*\)$%\1\n\tFontPath     \"$FP\"%"
#  fi
#done


# check for nvidia card
VOD="x11"
OGL=xorg-x11
modprobe nvidia > /dev/null 2>&1
if [ "$(lspci -v| grep "Kernel driver in use: nvidia")" != "" ] ; then
   nvidia-xconfig --no-composite --custom-edid=DFP-0:/etc/X11/edid.bin --no-connect-to-acpid --depth=24 \
                  --disable-glx-root-clipping --damage-events --overlay --overlay-default-visual \
                  --render-accel --add-argb-glx-visuals --no-use-edid-dpi --no-use-edid-freqs
fi

# check for newer nvidia card, if present install newer nvidia-driver
if [ "$(grep "Driver.*\"nv\"" $X_CFG)" != "" ] ; then
   modprobe -r nvidia
   sed -i /etc/portage/package.mask/x11 -e "/.*\/nvidia-.*/d"
#   echo ">=x11-drivers/nvidia-drivers-341" >>/etc/portage/package.mask/x11
   ACCEPT_KEYWORDS="~x86" emerge -u --usepkgonly --nodeps nvidia-drivers
   modprobe nvidia > /dev/null 2>&1
   nvidia-xconfig --no-composite --custom-edid=DFP-0:/etc/X11/edid.bin --no-connect-to-acpid --depth=24 \
                  --disable-glx-root-clipping --damage-events --overlay --overlay-default-visual \
                  --render-accel --add-argb-glx-visuals --no-use-edid-dpi --no-use-edid-freqs
fi

cat $X_CFG.default >> $X_CFG
if [ "$(lspci -v| grep "Kernel driver in use: nvidia")" != "" ] ; then
   sed -i $X_CFG -e "s/Device0/Card0/"
   OGL=nvidia
   VOD="vdpau"
#   sed -i $X_CFG -e "s/\(.*\)\(FlatPanelProperties.*\)/\1\2\n\1OnDemandVBlankInterrupts\" \"true\"/"
else
   modprobe radeon > /dev/null 2>&1
   if [ "$(lspci -v| grep "Kernel driver in use: radeon")" != "" ] ; then
      cp -av $X_CFG.amd $X_CFG
      sed -i $X_CFG -e "s/\(.*\)Driver\(.*\)vesa/\1Driver\2radeon/"
      VOD="vdpau"
   else
      screen -dm sh -c "X"
      echo "Checking for intel va-api"
      [ "$(lsmod | grep i915)" != "" ] && VOD="vaapi"
   fi
fi



# Add defaults

$SETVAL VO_DRIVER $VOD
$SETVAL -x PLG_xine 0
sed -i ${VDR_SOURCE_DIR}/Make.plgcfg -e "s%OPENGLOSD = .%OPENGLOSD = 0%"
if [ "$VOD" == "vdpau" ] ; then
   if [ "$OGL" = "nvidia" ] ; then
      sed -i ${VDR_SOURCE_DIR}/Make.plgcfg -e "s%OPENGLOSD = .%OPENGLOSD = 1%"
      set_softhd OPENGL
      $SETVAL -x PLG_tvguideng 97
      $SETVAL -x PLG_tvguide 0
      sed -i /etc/vdr/setup.conf -e "s/OSDSkin = .*/OSDSkin = estuary4vdr/"
   else
      $SETVAL -x PLG_tvguideng 0
      $SETVAL -x PLG_tvguide 97
      set_softhd VPP
      sed -i /etc/vdr/setup.conf -e "s/OSDSkin = .*/OSDSkin = nOpacity/"
   fi
   $SETVAL -x PLG_softhddevice 99
   $SETVAL -x PLG_vaapidevice 0
   $SETVAL -x PLG_xineliboutput 0
   $SETVAL -x PLG_skinnopacity 98
   $SETVAL -x PLG_skindesigner 96
elif [ "$VOD" == "vaapi" ] ; then
   $SETVAL -x PLG_softhddevice 0
   $SETVAL -x PLG_vaapidevice 99
   $SETVAL -x PLG_xineliboutput 0
   $SETVAL -x PLG_skinnopacity 98
   $SETVAL -x PLG_skindesigner 96
   $SETVAL -x PLG_tvguideng 97
   $SETVAL -x PLG_tvguide 0
   sed -i /etc/vdr/setup.conf -e "s/OSDSkin = .*/OSDSkin = estuary4vdr/"
else
   $SETVAL -x PLG_softhddevice 0
   $SETVAL -x PLG_vaapidevice 0
   $SETVAL -x PLG_skinnopacity 0
   $SETVAL -x PLG_skindesigner 0
   $SETVAL -x PLG_tvguideng 0
   $SETVAL -x PLG_tvguide 98
   $SETVAL -x PLG_xineliboutput 99
fi

# set keyboard layout
/etc/vdr/plugins/admin/cfglang.sh

eselect opengl set $OGL
sed -i $X_CFG -e "s/Screen [ ]*0.*/Screen 0 \"S_PC\"/"
[ "$(pidof X)" = "" ] && screen -dm sh -c "X"
echo "Checking for x resolution"
sleep 3
RES=""
for i in $(seq 1 10) ; do
   echo "XPID: $(pidof X)"
   RES=$(xrandr --verbose 2>/dev/null| grep "\*current" | cut -f 1 -d "(")
   [ "$RES" != "" ] && break
   sleep 1
done
if [ "$RES" != "" ] ; then
   [ "${RES/*1920*/}" == "" ] && RES="1080p"
   /etc/vdr/plugins/admin/setadmval.sh -x SCREEN_RESOLUTION $RES
else
   sed -i $X_CFG -e "s/Screen [ ]*0.*/Screen 0 \"Screen0\"/"
fi
rm /root/xorg.conf.new /xorg.conf.new > /dev/null 2>&1

killall X
