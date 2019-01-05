#!/bin/bash
source /_config/bin/g2v_funcs.sh
#Bootmanager (Grub/Lilo)
BOOTMAN="Grub"
#Bootsplash (0/1)
BOOTSPLASH=0
#Vesafb (0/1)
VESAFB=1

LILO_CONF="/etc/lilo.conf"
VESA="video=uvesafb:.*"
VESA_OFF="video=uvesafb:off\""
VESA_ON="video=uvesafb:800x600-16@60\""
VESA_ON_SPLASH="video=uvesafb:800x600-16@60 splash=silent,theme:vdr quiet CONSOLE=/dev/tty1\""

#read-only
#initrd = /boot/fbsplash-vdr-800x600

glogger -s "ADMIN - Framebuffer: $VESAFB"

if [ "$BOOTMAN" = "Grub" ] ; then
   grub-install --recheck /dev/hda
else   
   if [ "$VESAFB" = "1" ] ; then
      if [ "$BOOTSPLASH" = "1" ] ; then
         sed -i $LILO_CONF -e "s/$VESA_OFF/$VESA_ON_SPLASH/" \
                           -e "s%^#initrd = /boot/fb%initrd = /boot/fb%"
      else
         sed -i $LILO_CONF -e "s/$VESA_OFF/$VESA_ON/" \
                           -e "s%^initrd = /boot/fb%#initrd = /boot/fb%"
      fi
      glogger -s "ADMIN - BootSplash: $VESAFB"
   else
      sed -i $LILO_CONF -e "s/$VESA_ON/$VESA_OFF/" \
                        -e "s%^initrd = /boot/fb%#initrd = /boot/fb%"
   fi			
   lilo.sh
fi

echo 'Done!'
exit 0

