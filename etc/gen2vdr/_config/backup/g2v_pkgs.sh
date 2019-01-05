#!/bin/bash
URL_PKGS="http://www.htpc-forum.de/gen2vdr/2.0/packages"
OPTS="--no-cache "
MD5_FILE="g2v_md5_pkgs"
TARGET_DIR="g2v_inst/mnt/data/portage/packages/All"

if [ "$1" != "-all" -a "$1" != "-list" -a "$1" != "-get" ] ; then
   echo "Syntax: $0 -all|-list|-get"
   echo "   -all:  lade alle packages"
   echo "   -list: hole Liste der packages (g2v_md5_pkgs)"
   echo "   -get:  hole alle in Pakete der Liste"
   exit
fi   

if [ ! -d g2v_inst ] ; then
   echo "Installationsverzeichnis g2v_inst nicht vorhanden"
fi
mkdir -p $TARGET_DIR > /dev/null 2>&1   
 
if [ "$1" != "-get" ] ; then
   rm -f $MD5_FILE >/dev/null 2>&1
   wget $OPTS "${URL_PKGS}/${MD5_FILE}"
   if [ ! -f $MD5_FILE ] ; then
      OPTS=""
      wget "${URL_FILES}/${MD5_FILE}"
   fi
fi   
[ "$1" = "-list" ] && exit

ARCHS=$(cat $MD5_FILE | cut -f 3 -d " ")
if [ "${ARCHS}" = "" ] ; then
   echo "Fehler beim Download von ${MD5_FILE}"
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
