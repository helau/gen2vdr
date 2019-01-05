#!/bin/sh
source /_config/bin/g2v_funcs.sh
if [ "$GUI_FONTSIZE" != "" ] && [ $GUI_FONTSIZE -gt 7 ] ; then
#   sed -i /home/vdr/.kde4/share/config/kcmfonts /root/.kde4/share/config/kcmfonts -e "s/^forceFontDPI.*/forceFontDPI=120/"
#   SF=$((GUI_FONTSIZE - 2))
#   for i in desktopFont fixed font menuFont taskbarFont toolBarFont activeFont ; do
#      sed -i /home/vdr/.kde4/share/config/kdeglobals /root/.kde4/share/config/kdeglobals \
#          -e "s/^\(${i}=[^,]*\),[^,]*,\(.*\)/\1,${GUI_FONTSIZE},\2/"
#   done
#   for i in smallestReadableFont ; do
#      sed -i /home/vdr/.kde4/share/config/kdeglobals /root/.kde4/share/config/kdeglobals \
#          -e "s/^\(${i}=[^,]*\),[^,]*,\(.*\)/\1,${SF},\2/"
#   done
   sed -i /root/.config/Trolltech.conf /home/vdr/.config/Trolltech.conf \
       -e "s/^\(font=[^,]*\),[^,]*,\(.*\)/\1,${GUI_FONTSIZE},\2/"
#   sed -i /home/vdr/.gtkrc-2.0 /root/.gtkrc-2.0 -e "s/\(.* \)[0-9]*\"/\1${GUI_FONTSIZE}\"/"
fi
