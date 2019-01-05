#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
glogger -s "$0 - $1 - $2"

ALL_DISKS=$(mount |grep "on /media.*rw" | cut -f 3 -d " ") #"
DISK_FREE=0
VID_DIR=/mnt/data/video
BKP_DISK=""
for i in $ALL_DISKS; do
   DF=$(df "$i" | tail -n 1 | tr -s " "| cut -f 4 -d " ")
   if [ $DF -gt $DISK_FREE ] ; then
      DISK_FREE=$DF
      BKP_DISK=$i
   else
      echo "$i ist kleiner"
   fi
done
echo "$BKP_DISK : $DISK_FREE free"
TGT=${BKP_DISK%/}/video
[ ! -e "$TGT" ] && mkdir -p "$TGT"
echo "Target: $TGT"
#set -x
echo "" > /tmp/move2usb.status
REC_NUM=$(find $VID_DIR -type f -name "index" -amin +20 | wc -l)
ACT_NUM=1
while read i ; do
   REC_DIR=${i%/index}
   DF=$(df "$TGT" | tail -n 1 | tr -s " "| cut -f 4 -d " ")
   DU=$(du "$REC_DIR" | tr "\t" " " | cut -f 1 -d " ")
   if [ $DU -lt $DF ] ; then
      TGT_DIR="${TGT}${REC_DIR#${VID_DIR}}"
      if [ -e "${TGT_DIR}" ] ; then
         echo "$TGT_DIR existiert bereits"
      else
         echo "Kopiere (${ACT_NUM}/${REC_NUM}) <$REC_DIR>"
         echo "Kopiere (${ACT_NUM}/${REC_NUM}) <$REC_DIR>" > /tmp/move2usb.status
         mkdir -p "${TGT_DIR%/*}"
         cp -av "${REC_DIR}" "${TGT_DIR%/*}/"
         if [ $? == 0 ] ; then
            echo "Loesche <$REC_DIR>" >> /tmp/move2usb.status
            rm -rvf "$REC_DIR"
         fi
      fi
   else
      echo "Zu wenig freier Platz fuer <${REC_DIR}>"
      echo "Zu wenig freier Platz fuer <${REC_DIR}>" >> /tmp/move2usb.status
   fi
   ACT_NUM=$((ACT_NUM+1))
done < <(find $VID_DIR -type f -name "index" -amin +20)
echo "Fertig !" >> /tmp/move2usb.status

