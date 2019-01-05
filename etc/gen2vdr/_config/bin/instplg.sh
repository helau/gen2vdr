#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh
FNAME=$1

if [ ! -s $1 ] ; then
   FN="$(echo $1 | sed -e "s&.*/&&g")"
   FNAME="/tmp/$FN"
   wget -O $FNAME ${1}
   if [ ! -s $FNAME ] ; then
      echo "Syntax: $0 [url|filename]"
      exit
   fi
else
   FNAME=$1
fi


if [ -s $FNAME ] ; then
   if [ "$(echo $FNAME |grep "\.tar\.bz2$")" != "" ] ; then
      TAROPT="j"
   elif [ "$(echo $FNAME |grep "\.tbz$")" != "" ] ; then
      TAROPT="j"
   elif [ "$(echo $FNAME |grep "\.tar\.gz$")" != "" ] ; then
      TAROPT="z"
   elif [ "$(echo $FNAME |grep "\.tgz$")" != "" ] ; then
      TAROPT="z"
   else
      echo "Unsupport archiv file <$FNAME>"
      exit
   fi
   PLUG_VERSION=$(tar -t${TAROPT}f $FNAME |grep -m1 Makefile|cut -f 1 -d "/")
   if [ "${PLUG_VERSION}" = "." ] ; then
      PLUG_VERSION=$(tar -t${TAROPT}f $FNAME |grep -m1 Makefile|cut -f 2 -d "/")
   fi
   if [ -d ${VDR_SOURCE_DIR}/PLUGINS/src/${PLUG_VERSION} ] ; then
      echo "${VDR_SOURCE_DIR}/PLUGINS/src/${PLUG_VERSION} bereits vorhanden"
      exit
   fi
   PLUGIN=$(echo $PLUG_VERSION | cut -f 1 -d "-")
   tar -C ${VDR_SOURCE_DIR}/PLUGINS/src -x${TAROPT}vf "$FNAME"
   cd ${VDR_SOURCE_DIR}/PLUGINS/src
   RESTART=0
   if [ -d ${PLUG_VERSION} ] ; then
      [ -d $PLUGIN ] && rm $PLUGIN
      ln -s ${PLUG_VERSION} ${PLUGIN}
      cd $PLUGIN
      make clean
      make all
      if [ "$?" = "0" ] ; then
         ls -ld ${VDR_SOURCE_DIR}/PLUGINS/src/${PLUGIN}*
         if [ "${PLUGIN}" = "xineliboutput" ] ; then
            make install
            cp -afp ${VDR_SOURCE_DIR}/vdr-??fe /usr/bin/ >/dev/null 2>&1
         fi
         if [ "${PLUGINS/* PLUGIN */}" != "" ] ; then
            PP="-f"
         fi
         sh /_config/bin/instvdr.sh $PP
         echo "Plugin Parameter werden in /etc/vdr.d/plugins/$PLUGIN gesetzt"
         [ -d $PLUGIN ] && cp -a $PLUGIN /etc/vdr/plugins/
      else
         echo "Error compiling ${PLUGIN}"
      fi
      ls -ld ${VDR_SOURCE_DIR}/PLUGINS/src/${PLUGIN}*
   else
      echo "${PLUG_VERSION} not found"
   fi
else
   echo "$FNAME not found"
fi
