#!/bin/bash
#set -x
URL_FIXES="http://www.gen2vdr.org/files/v3/1.0/fixes"
MD5_FILE="g2v_md5_fixes"
FILES_TO_FETCH="setup.sh setuphd.sh autorun g2v_mki.sh"
OPTS="--no-cache "
CD_MD5_FILE="g2v_inst/_config/update/$MD5_FILE"

rm -f $FILES_TO_FETCH $MD5_FILE $CD_$MD5_FILE >/dev/null 2>&1

wget $OPTS "${URL_FIXES}/${MD5_FILE}" >/dev/null 2>&1
if [ ! -f ${MD5_FILE} ] ; then
   OPTS=""
   wget "${URL_FIXES}/${MD5_FILE}" >/dev/null 2>&1
fi  
for i in $FILES_TO_FETCH ; do
   echo "Fetching $i"
   wget $OPTS "${URL_FIXES}/${i}" >/dev/null 2>&1
done

mkdir -p g2v_inst/_config/update

ARCHS=$(cat $MD5_FILE 2>/dev/null | cut -f 3 -d " ")
#set -x
for i in $ARCHS ; do
   found=""
   if [ -f ${i} ] ; then
      echo "Checking md5sum <${i}> ..."
      MD5=$(md5sum ${i} | cut -f 1 -d " ")
      ORG_MD5=$(grep "${i}" ${MD5_FILE}| cut -f 1 -d " ")
      if [ "$MD5" = "$ORG_MD5" ] ; then
         found="1"
      else
         rm -f ${i}
      fi
   fi
   if [ "$found" = "" ] ; then
      echo "Downloading <${i}> ..."
      wget $OPTS ${URL_FIXES}/${i}
      MD5=$(md5sum ${i} | cut -f 1 -d " ")
      if [ "$(grep "${i}" "${MD5_FILE}" | grep $MD5)" = "" ] ; then
         echo "Error getting ${i}"
         exit -1
      fi
   fi
   if [ "$i" = "g2v_cdupdate.tar.bz2" ] ; then
      bzip2 -d -c $i > g2v_cdupdate.tar
      tar -xvf g2v_cdupdate.tar
      rm g2v_cdupdate.tar
   else
      cp -f $i g2v_inst/_config/update/.
      echo "$MD5  $i" >> $CD_MD5_FILE
   fi
done
