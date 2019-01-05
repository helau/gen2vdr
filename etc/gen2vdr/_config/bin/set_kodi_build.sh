#!/bin/bash
KODI=/etc/portage/package.keywords/kodi
CFG=/_config/portage/kodi
if [ -e "${CFG}_$1" ] ; then
   echo "Switching to Kodi $1 ..."
else
   echo "Invalid parameter - must be stable or unstable"
   exit
fi
rm -f $KODI
ln -sf ${CFG}_$1 $KODI
emerge -auvDN $(qlist -I "kodi\-*")
emerge -av @preserved-rebuild
