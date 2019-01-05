#!/bin/bash
URL_PKGS="http://ftp.gwdg.de/pub/linux/mediaportal/helau/ActivyEdition/packages"
OPTS="--no-cache "
MD5FL="g2v_md5_pkgs"
MD5_FILE="/_config/update/g2v_md5_pkgs"
TARGET_DIR="/usr/portage/packages/All"

if [ "$1" != "-all" -a "$1" != "-list" -a "$1" != "-get" -a "$1" != "-install" ] ; then
   echo "Syntax: $0 -all|-list|-get"
   echo "   -all:      lade alle packages und installiere diese"
   echo "   -list:     hole Liste der packages (g2v_md5_pkgs)"
   echo "   -get:      hole alle in Pakete der Liste"
   echo "   -install:  installiere alle in Pakete der Liste"
   exit
fi   

[ ! -d $TARGET_DIR ] && mkdir -p $TARGET_DIR
 
if [ "$1" = "-list" -o "$1" = "-all" ] ; then
   rm -f $MD5_FILE >/dev/null 2>&1
   wget $OPTS -O $MD5_FILE "${URL_PKGS}/${MD5FL}"
   if [ ! -f $MD5_FILE ] ; then
      OPTS=""
      wget -O $MD5_FILE "${URL_PKGS}/${MD5FL}"
   fi
fi   
if [ ! -f $MD5_FILE ] ; then
   echo "$MD5_FILE nicht vorhanden"
   exit
fi

if [ "$1" = "-list" ] ; then
   mcedit $MD5_FILE
   exit
fi

ARCHS=$(cat $MD5_FILE | cut -f 3 -d " ")
if [ "${ARCHS}" = "" ] ; then
   echo "Fehler beim Download von ${$MD5_FILE}"
   exit -1
fi

for i in $ARCHS ; do
   WP=""
   if [ -f ${TARGET_DIR}/${i} ] ; then
      echo "Pruefe <${TARGET_DIR}/${i}> ..."
      MD5=$(md5sum ${TARGET_DIR}/${i} | cut -f 1 -d " ")
      if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" != "" ] ; then
         continue
      else
         WP="-c "
      fi
   fi
   echo "Lade <${i}> herunter ..."
   wget $OPTS $WP -O ${TARGET_DIR}/$i ${URL_PKGS}/${i}
   MD5=$(md5sum ${TARGET_DIR}/${i} | cut -f 1 -d " ")
   if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" = "" ] ; then
      echo "Fehler beim Download von ${i}"
      if [ -f $i ] ; then
         echo "Nochmaliger Download von ${i} ..."
         rm $i
         wget $OPTS $WP -O ${TARGET_DIR}/$i ${URL_PKGS}/${i}
         MD5=$(md5sum ${TARGET_DIR}/${i} | cut -f 1 -d " ")
         
         if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" = "" ] ; then
            echo "Fehler beim Download von ${i}"
            exit -1
         fi
      else
         exit -1             
      fi
   fi
done

if [ "$1" = "-get" ] ; then
   exit
fi

ALL_PKGS=$(cat $MD5_FILE |sed -e "s/\.tbz2.*//" -e "s/.* /=/")

if [ "$ALL_PKGS" != "" ] ; then
   emerge -auv --usepkgonly $ALL_PKGS
else
   echo "Nichts zu installieren in $MD5_FILE"
fi