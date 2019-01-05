#!/bin/bash
VDR_DIR=/usr/local/src/VDR

VV=$(readlink ${VDR_DIR})
#set -x
CheckDiff() {
#   echo "Suche Patches"
   PLG=${1%%-*}
   DIFF="${VDR_DIR}/../patches/${VV}/plugins/${1}.diff"
   [ ! -e "$DIFF" ] &&  DIFF="${VDR_DIR}/../patches/${VV}/plugins/${PLG}.diff"
   if [ -e "$DIFF" ] ; then
      echo -e "\nPatch für Plugin $PLG <${DIFF##*/}>"
      cd ${VDR_DIR}/PLUGINS/src/${1}
      patch -p1 --dry-run -f < "${DIFF}"
      if [ "$?" != "0" ] ; then
         patch -p0 --dry-run -f < "${DIFF}"
         if [ "$?" != "0" ] ; then
            echo -e "\n\nPatch für $1 fehlgeschlagen - Enter für weiter, Ctrl-c für Abbruch\n"
            read
         else
            patch -p0 -f < "${DIFF}"
         fi
      else
         patch -p1 -f < "${DIFF}"
      fi
   fi
   PSH="${VDR_DIR}/../patches/${VV}/plugins/${1}.sh"
   [ ! -e "${PSH}" ] && PSH="${VDR_DIR}/../patches/${VV}/plugins/${PLG}.sh"
   if [ -e "${PSH}" ] ; then
      echo -e "\nScript für Plugin $PLG <${PSH##*/}>"
      cd ${VDR_DIR}/PLUGINS/src/${PLG}
      bash "${PSH}"
   fi
   [ "$(grep IMAGELIB ${VDR_DIR}/PLUGINS/src/${1}/Makefile 2>/dev/null)" != "" ] && sed -i ${VDR_DIR}/PLUGINS/src/${1}/Makefile -e "s%IMAGELIB = imagemagick%IMAGELIB = graphicsmagick%" 2>/dev/null
}

cd ${VDR_DIR}/PLUGINS/src
TMPFILE=/tmp/.upd
rm -f $TMPFILE
for i in *-git ; do
   [ ! -d $i ] && continue
   cd ${VDR_DIR}/PLUGINS/src/$i
   echo $i
#   rm po/*.po
#   rm plugin/po/*.po
#   A=$(git rev-parse @)
#   B=$(git rev-parse "@{u}")
#   if [ "$A" != "$B" ] ; then
      original_head=$(git rev-parse HEAD)
      git reset --hard HEAD >/dev/null 2>&1
      git clean -f -d >/dev/null 2>&1
      git pull
      updated_head=$(git rev-parse HEAD) 
      [ "$original_head" != "$updated_head" ] && echo -e "  $i --> $(git log --oneline |head -n1)" >> $TMPFILE
      CheckDiff $i
#   fi
   cd ${VDR_DIR}/PLUGINS/src
done
for i in *-svn ; do
   [ ! -d $i ] && continue
   cd ${VDR_DIR}/PLUGINS/src/$i
   echo $i
   svn up >/dev/null 2>&1
   CheckDiff $i
   cd ${VDR_DIR}/PLUGINS/src
done
for i in *-cvs ; do
   [ ! -d $i ] && continue
   cd ${VDR_DIR}/PLUGINS/src/$i
   echo $i
   cvs up >/dev/null 2>&1
   CheckDiff $i
   cd ${VDR_DIR}/PLUGINS/src
done
for i in *-hg ; do
   [ ! -d $i ] && continue
   cd ${VDR_DIR}/PLUGINS/src/$i
   echo $i
   hg pull >/dev/null 2>&1
   CheckDiff $i
   cd ${VDR_DIR}/PLUGINS/src
done
set +x
if [ -s $TMPFILE ] ; then
   echo -e "Folgendende Plugins wurden aktualisiert:\n$(cat $TMPFILE)"
else
   echo "Alle Plugins sind up-to-date"
fi
