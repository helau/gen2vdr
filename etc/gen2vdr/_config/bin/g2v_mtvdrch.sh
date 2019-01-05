#!/bin/bash
LOGO_DIR="/etc/vdr/plugins/skinnopacity/logos/"
VDRS_DIR="/var/vdr/mediatomb/channels"

#set -x
rm -rf ${VDRS_DIR}/[0-9]* 2>/dev/null
mkdir -p "${VDRS_DIR}" 2>/dev/null

svdrpsend LSTC | grep "^250" | while read i ; do
   CHNUM=${i%% *}
   CHNUM="${CHNUM#*-}"
   CHANUM="000${CHNUM#*-}"
   CHANUM="${CHANUM: -4}"
   CHNAME=${i#* }
   CHNAME=${CHNAME%%;*}
   FN="${CHNAME#*,}"
   LOGO=""
   for j in "${CHNAME%,*}" "${CHNAME#*,}" "${CHNAME}" ; do
      if [ -e "${LOGO_DIR}${j,,}.png" ] ; then
         LOGO="${LOGO_DIR}${j,,}.png"
         FN=${j}
         break
      fi
   done
   FN="${FN//\*/_}"
   FN="${FN//\//_}"
   echo "URL=http://127.0.0.1:3000/TS/$CHNUM" > "${VDRS_DIR}/${CHANUM}-${FN// /_}.vdrs"
   [ "$LOGO" != "" ] && echo "LOGO=$LOGO" >> "${VDRS_DIR}/${CHANUM}-${FN// /_}.vdrs"
   [ $CHNUM -gt 1 ] && break
done
