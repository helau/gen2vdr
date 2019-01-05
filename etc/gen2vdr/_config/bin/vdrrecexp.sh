#!/bin/bash
set -x
SRC=$1
TGT=$2
if [ "$TGT" == "" ] || [ ! -d "$2" ] ; then
   echo "Syntax: $0 <source> <target>"
   exit
fi

find "$SRC" -name "*.rec" -type d | while read i ; do
   TITLE=$(grep "^T" "${i}/info" | cut -f 2- -d " " | sed -e "s%[^a-zA-Z0-9.-_]%_%g" | tr -s "_")
   SUBTITLE=$(grep "^S" "${i}/info" | cut -f 2- -d " " | sed -e "s%[^a-zA-Z0-9.-_]%_%g" | tr -s "_")
   TITLE=${TITLE#_}
   TITLE=${TITLE%_}
   SUBTITLE=${SUBTITLE#_}
   SUBTITLE=${SUBTITLE%_}

   [ "$TITLE" == "" ] && TITLE="Unknown"
   if [ "$SUBTITLE" != "" ] ; then
      TGT_TITLE="${TITLE}_-_${SUBTITLE}"
   else
      TGT_TITLE="${TITLE}"
   fi
   if [ -e "${TGT%/}/${TGT_TITLE}.ts" ] ; then
      for j in $(seq -f "%02g" 99) ; do
         if [ ! -e "${TGT%/}/${TGT_TITLE}_${j}.ts" ] ; then
            TGT_TITLE="${TGT_TITLE}_${j}"
            break
         fi
      done
   fi
   echo "cat ${i}/0*.ts > ${TGT%/}/${TGT_TITLE}.ts"
   cat "${i}"/0*.ts > "${TGT%/}/${TGT_TITLE}.ts"
done
