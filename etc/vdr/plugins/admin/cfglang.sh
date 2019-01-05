#!/bin/bash
#
source /etc/vdr.d/conf/vdr

if [ "$KBD_LAYOUT" = "US" ]; then
  XKBD="us"
  XVAR="#"
  CKBD="us"
else
  XKBD="de"
  XVAR=" "
  CKBD="de-latin1-nodeadkeys"
fi
#sed -i /etc/X11/xorg.conf -e "s/InputDevice.*\"Keyboard.*/InputDevice \"Keyboard${XKBD}\" \"CoreKeyboard\"/"
sed -i /etc/conf.d/keymaps -e "s/^keymap[= ].*/keymap=\"$CKBD\"/"

X_CFG="/etc/X11/xorg.conf"
X_EVCFG="/etc/X11/xorg.conf.d/10-evdev.conf"
# set keyboard
if [ "$(grep "xkb_layout" $X_CFG)" = "" ] ; then
   sed -i $X_CFG -e "s/\(.*\)Driver\(.*\)\"kbd\"/\1Driver\2\"kbd\"\n\1Option\2\"xkb_layout\" \"de\"\n\1Option\2\"xkb_model\" \"pc105\"\n\1Option\2\"xkb_variant\" \"nodeadkeys\"/"
fi
sed -i $X_CFG $X_EVCFG -e "s/\(.*\"xkb_layout\"\).*/\1 \"$XKBD\"/"
sed -i $X_CFG $X_EVCFG -e "s/.\(.*\"xkb_model\"\.*\)/${XVAR}\1/" -e "s/.\(.*\"xkb_variant\"\.*\)/${XVAR}\1/"
