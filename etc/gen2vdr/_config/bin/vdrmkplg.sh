#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ "$1" != "clean" ] ; then
   echo "Making vdr ..."
   cd ${VDR_SOURCE_DIR}
   make include-dir
   make
fi

if [ "$1" = "" ]  ; then
   MKP="all"
else
   MKP="$*"
fi
ALL_PLGS=$(ls ${VDR_SOURCE_DIR}/PLUGINS/src)
for i in $PLUGINS ; do
   echo ""
   PLG=$(echo "$i" | cut -f 1 -d "-")
   if [ -e ${VDR_SOURCE_DIR}/PLUGINS/src/$PLG ] ; then
      PLG=$i
   else 
      case $PLG in
         mplayer)    PLG="mp3";;
         streamdev*) PLG="streamdev";;
         X10)        PLG="x10";;
         svc*)       PLG="servicedemo";;
         *)          echo "Plugin <$i><$PLG> not found"
                     exit;;
      esac  
      if [ ! -e ${VDR_SOURCE_DIR}/PLUGINS/src/$PLG ] ; then
         echo "Plugin <$i><$PLG> not found"
         exit
      fi   
      echo "$i -> $PLG"
   fi
   
   cd ${VDR_SOURCE_DIR}/PLUGINS/src/$PLG
   echo "Making <$PLG> $MKP ..."
   make $MKP
done   
sh /etc/vdr/plugins/admin/cfgplg.sh
exit
