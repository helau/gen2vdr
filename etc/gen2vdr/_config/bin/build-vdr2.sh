#!/bin/bash
source /_config/bin/g2v_funcs.sh

# Log everything
LOG_FILE="/log/$(basename ${0%.*}).log"
echo "Started at: $(date +'%F %R')" > ${LOG_FILE}
exec 1> >(tee -a ${LOG_FILE}) 2>&1

BUILD_OLD_PLGS=0
#set -x
CLEAN_BUILD=1
CPUS=$(grep -c "^processor" /proc/cpuinfo)
JC=$((CPUS + 2))
DEBUG=1

[ "$1" == "-a" ] && AUTO=1

cd $VDR_SOURCE_DIR

if [ "$AUTO" != 1 ] ; then
   echo -e "\n\nSollen die Plugins aktualisiert werden ? (J/n)\n"
   read choice
else
   choice="J"
fi
if [ "${choice,,}" != "n" ] ; then
   bash /_config/bin/g2v_updplgs.sh
fi

if [ "$AUTO" != 1 ] ; then
   echo -e "\n\nSollen die Skindesigner-Skins aktualisiert werden ? (J/n)\n"
   read choice
else
   choice="J"
fi
if [ "${choice,,}" != "n" ] ; then
   bash /_config/bin/g2v_updskins.sh
fi

cd $VDR_SOURCE_DIR

if [ "$AUTO" != 1 ] ; then
   echo -e "\n\nSoll debug code erzeugt werden ? (J/n)\n"
   read choice
else
   choice="J"
fi
if [ "${choice,,}" != "n" ] ; then
   sed -i Make.config -e "s/^#.*GDB_DEBUG.*/GDB_DEBUG = 1/"
else
   sed -i Make.config -e "s/^GDB_DEBUG/#GDB_DEBUG/"
   DEBUG=0
fi

echo "Baue libskindesignerapi"

cd PLUGINS/src/skindesigner/libskindesignerapi
make clean
make install

cd $VDR_SOURCE_DIR

if [ "$AUTO" != 1 ] ; then
   echo -e "\n\nSoll clean gebaut werden ? (J/n)\n"
   read choice
else
   coice="J"
fi
if [ "${choice,,}" != "n" ] ; then
   cd $VDR_SOURCE_DIR
   echo -e "\n\n Make clean ...\n\n"
   make LCLBLD=1 -j${JC} clean
   make vdr.pc
   make LCLBLD=1 -j${JC} clean-plugins
   cd $VDR_SOURCE_DIR
   rm -rf PLUGINS/lib/*
   rm -f $(find . -name ".depend*" -or -name "*.so.*" -or -name "*.mo" -or -name "*.so" -or -name ".depend*")
fi

echo -e "\n\nMake VDR ...\n\n"
make LCLBLD=1 -j${JC} vdr     #make -j${JC} vdr
[ "$?" != "0" ] && echo -e "\n\nBaufehler - Abbruch\n" && exit 1
make LCLBLD=1 install-includes

#echo -e "\n\nSuche Makefiles die configure benoetigen ...\n\n"

#cd ${VDR_SOURCE_DIR}/PLUGINS/src

#ls */configure| grep -v '[^a-z0-9/]' | while read i ; do
#   cd ${VDR_SOURCE_DIR}/PLUGINS/src/${i%/*}
#   ./configure
#done

if [ "$BUILD_OLD_PLGS" == "1" ] ; then
   echo -e "\n\nBaue alte Plugins ...\n\n"
   cd ${VDR_SOURCE_DIR}

   for i in $(ls PLUGINS/src | grep -v '[^a-z0-9]') ; do
      cd ${VDR_SOURCE_DIR}/PLUGINS/src/${i}
#      [ -e configure ] && ./configure
      if [ "$(grep "PKGCFG" "Makefile")" = "" ] ; then
         make -j${JC} all
      fi
   done
fi
cd ${VDR_SOURCE_DIR}
rm -f /tmp/plg.out
make LCLBLD=1 -j${JC} plugins | tee /tmp/plg.out
FAILED_PLG=$(grep "^*** failed plugins: " /tmp/plg.out | cut -f 2 -d ":")
if [ "$FAILED_PLG" != "" ] ; then
   PLG_FAILED=""
   echo -e "\nBaue fehlerhafte Plugins <$FAILED_PLG> erneut ...\n\n"
   for i in $FAILED_PLG ; do
      cd ${VDR_SOURCE_DIR}/PLUGINS/src/${i}
      make -j${JC} all
      [ "$?" != "0" ] && PLG_FAILED="$PLG_FAILED $i"
      [ "$(grep "install:" Makefile)" != "" ] && make install
   done
   if [ "$PLG_FAILED" == "" ] ; then
      echo -e "\n\nAlle Plugins wurden erfolgreich gebaut !\n\n"
   else
      echo -e "\n\nDiese Plugins konnten nicht gebaut werden: ${PLG_FAILED} !\n\n"
   fi
fi

if [ "$AUTO" != 1 ] ; then
   echo -e "\n\nSoll VDR installiert werden  ? (J/n)\n"
   read choice
else
   choice="J"
fi
if [ "${choice,,}" != "n" ] ; then
   bash /_config/bin/instvdr.sh $DEBUG
fi

if [ "$PLG_FAILED" == "" ] ; then
   echo -e "\n\nAlle Plugins wurden erfolgreich gebaut !\n\n"
else
   echo -e "\n\nDiese Plugins konnten nicht gebaut werden: ${PLG_FAILED} !\n\n"
fi
