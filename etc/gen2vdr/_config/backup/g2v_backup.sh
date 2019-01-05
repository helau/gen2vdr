#!/bin/bash
source /etc/g2v-release
source /_config/bin/g2v_funcs.sh

MIN_FREE=2000
ISOLX_DIR="isolinux"
INST_DIR="/_config/backup"
TARGET_DIR="/mnt/data/backup"
TARGET="$TARGET_DIR/${ID}_$(date +%y%m%d).iso"
XZ_OPTS="-2"
TAR_OPTS="-cJpf"

cd $INST_DIR
INSTALL=""
KRNLALL=""
#set -x
function syntax() {
   echo ""
   echo "Syntax: $0 [-b][-k][file]"
   echo "               -b   : Create machine specific Backup (not universal install)"
   echo "               -k   : Include complete kernel including object files for faster recompiling"
   echo "               file : Name of image (Default: /mnt/data/g2vxx_yymmdd.iso)"
   echo "                      -n for no image file creation"
   echo ""
   exit
}

while [ "$1" != "" ] ; do
   case "$1" in
      -h|--help)
         syntax
         ;;
      -b)
         INSTALL="-b"
         ;;
      -k)
         KRNLALL="-k"
         ;;
      *)
         TARGET_DIR="$(dirname "$1")"
         TARGET="$1"
         ;;
   esac
   shift
done

echo "Erstelle Backup von Gen2VDR ${VERSION%% *} - ${TARGET}"
killall -9 tar 2>/dev/null

DATE=$(date +"%d.%m.%Y")

[ ! -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR"
if [ -d "$TARGET_DIR" ] ; then
   if [ "${TARGET_DIR:0:1}" = "." ] ; then
      act_dir="$(pwd)"
      cd $TARGET_DIR
      TARGET_DIR="$(pwd)"
      cd "$act_dir"
   fi
   rm -rf ${TARGET_DIR}/g2v*.xz
   freespace="$(df --block-size=1000000 "$TARGET_DIR" |tail -n 1 | tr -s " " |cut -f 4 -d " ")"
   if [ $freespace -lt $MIN_FREE ] ; then
      svdrps "MESG Kein Platz fuer Backup vorhanden"
      logger -s "Kein Platz fuer Backup vorhanden"
      syntax
   fi
else
   echo "<$TARGET_DIR> ist nicht vorhanden"
   syntax
fi

sed -i $ISOLX_DIR/message.txt -e "s#   Gen2VDR.*#   Gen2VDR ${VERSION%% *} - erstellt am $DATE#"
sed -i $ISOLX_DIR/README $ISOLX_DIR/INSTALL -e "s#^Gen2VDR.*#Gen2VDR ${VERSION%% *} - $DATE#"

. $INST_DIR/mkroot.sh $INSTALL 2>&1 | tee /tmp/mkroot.log &
. $INST_DIR/mkboot.sh $INSTALL 2>&1 | tee /tmp/mkboot.log &
. $INST_DIR/mkcfg.sh $INSTALL 2>&1 | tee /tmp/mkcfg.log &
. $INST_DIR/mksrc.sh $INSTALL $KRNLALL 2>&1 | tee /tmp/mksrc.log &

sleep 60
while [ "$(ps x|grep tee |grep "/tmp/mk")" != "" ] ; do
   sleep 3
done

DT=$(date +%m%d)
ls -l ${TARGET_DIR}/g2v* >> /mnt/data/backup/g2vbkp.log

touch -t ${DT}2000 $ISOLX_DIR/INSTALL $ISOLX_DIR/README $ISOLX_DIR/HISTORY setup.sh ${TARGET_DIR}/g2v*

. $INST_DIR/mkiso.sh $TARGET 2>&1 | tee /tmp/mkiso.log

svdrps "MESG Backup ist fertig ! ( $TARGET )"
