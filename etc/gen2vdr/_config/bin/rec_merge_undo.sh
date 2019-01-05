#!/bin/bash
#set -x
source /_config/bin/g2v_funcs.sh

# check if already running
if [ "$(pidof -x "$0" -o $$ -o $PPID -o %PPID)" != "" ] ; then
   glogger "ERROR: $0 laeuft bereits"
   exit
fi


# check if undo is possible
# Link for undo
SRC_DIR="$(readlink "${VIDEO}/rec_undo")"
SRC_DIR="${SRC_DIR%/}"

[ -e "${VIDEO}/rec_undo" ] && rm -f "${VIDEO}/rec_undo"

if [ ! -d "$SRC_DIR" ] ; then
   glogger "ERROR: UNDO UrsprungsVerzeichnis existiert nicht"
   exit
fi

TARGET_DIR="$(readlink "${SRC_DIR}/undo.link")"
if [ ! -d "${TARGET_DIR}" ] ; then
   glogger "ERROR: UNDO ZielVerzeichnis existiert nicht"
   exit
fi

cd "$TARGET_DIR"
du -hsb 0*.ts > "${SRC_DIR}/undo.info.new"

if [ "$(diff -uN "${SRC_DIR}/undo.info.new" "${SRC_DIR}/undo.info")" != "" ] ; then
   glogger "ERROR: UNDO ZielVerzeichnis hat sich geaendert"
   exit
fi
# move files
cd "$SRC_DIR"
for i in 0*.ts.undo ; do
   mv "$(readlink "$i")" "${i%.undo}"
   rm -f "$i"
done

# save marks, index and info
for i in marks index info.merged ; do
   if [ -e "${SRC_DIR}/${i}.undo" ] ; then
      cp -pf "${SRC_DIR}/${i}.undo" "${TARGET_DIR}/${i}"
      rm -f "${SRC_DIR}/${i}.undo"
   else
      [ -e "${TARGET_DIR}/${i}" ] && rm -f "${TARGET_DIR}/${i}"
   fi
done

rm -f undo.*

cd /
# create undo Link
SRC_REC="${SRC_DIR%.del}.rec"

mv -f "$SRC_DIR" "$SRC_REC"
touch /video/.update

glogger "<$0> wurde wieder geteilt"

screen -dm sh -c "sleep 10; touch /video/.update"
