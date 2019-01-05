#!/bin/bash
URL_FILES="http://www.gen2vdr.org/files/v3/1.0/files"
URL_FIXES="http://www.gen2vdr.org/files/v3/1.0/fixes"
OPTS="--no-cache "
MD5_FILE="g2v_md5_files"

rm -f $MD5_FILE >/dev/null 2>&1
wget $OPTS "${URL_FILES}/${MD5_FILE}"
if [ ! -f $MD5_FILE ] ; then
   OPTS=""
   wget "${URL_FILES}/${MD5_FILE}"
fi

ARCHS=$(cat $MD5_FILE | cut -f 3 -d " ")
if [ "${ARCHS}" = "" ] ; then
   echo "Fehler beim Download von ${MD5_FILE}"
   exit -1
fi

for i in $ARCHS ; do
   WP=""
   if [ -f ${i} ] ; then
      echo "Pruefe <${i}> ..."
      MD5=$(md5sum ${i} | cut -f 1 -d " ")
      if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" != "" ] ; then
         continue
      else
         WP="-c "
      fi
   fi
   echo "Lade <${i}> herunter ..."
   wget $OPTS $WP ${URL_FILES}/${i}
   MD5=$(md5sum ${i} | cut -f 1 -d " ")
   if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" = "" ] ; then
      echo "Fehler beim Download von ${i}"
      if [ -f $i ] ; then
         echo "Nochmaliger Download von ${i} ..."
         rm $i
         wget $OPTS $WP ${URL_FILES}/${i}
         MD5=$(md5sum ${i} | cut -f 1 -d " ")

         if [ "$(grep ${i} ${MD5_FILE} | grep $MD5)" = "" ] ; then
            echo "Fehler beim Download von ${i}"
            exit -1
         fi
      else
         exit -1
      fi
   fi
done

if [ -f g2v_boot.tar.bz2 ] ; then
   if [ ! -f g2v_boot.tar ] ; then
      bzip2 -d -c g2v_boot.tar.bz2 > g2v_boot.tar
   fi
   tar -xvf g2v_boot.tar
   rm g2v_boot.tar
fi

if [ -e g2v_inst ] ; then
   rm -rf g2v_inst > /dev/null 2>&1
fi
mkdir g2v_inst

if [ -f g2v_inst.tar.bz2 ] ; then
   if [ ! -f g2v_inst.tar ] ; then
      bzip2 -d -c g2v_inst.tar.bz2 > g2v_inst.tar
   fi
   tar -xvf g2v_inst.tar
   rm g2v_inst.tar
fi

if [ "$1" != "-t" ] ; then
   rm -f g2v_cdupdate.sh > /dev/null 2>&1
   wget $OPTS "${URL_FIXES}/g2v_cdupdate.sh" > /dev/null 2>&1
else
   URL_FIXES=""
fi

if [ -f g2v_cdupdate.sh ] ; then
   . ./g2v_cdupdate.sh
fi

[ ! -e myconf ] && mkdir myconf
cp setup.sh g2v_inst/default.conf myconf
