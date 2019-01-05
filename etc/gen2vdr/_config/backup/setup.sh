#!/bin/bash
trap "exit 0" 2

dmesg -n 1 >/dev/null 2>&1
######################################
# Installationsvorgaben
######################################

# Minimal erlaubte Groesse der Platte
SYS_MINSIZE=7000
VID_MINSIZE=10000
SWAP_MINSIZE=2000
BOOT_MINSIZE=50

# Standard Partitionsgroesse
SYSTEM_PART_SIZE=32768
SWAP_PART_SIZE=4096
BOOT_PART_SIZE=512

# Standard Filesystem
FS_ROOT="ext4"
FS_VIDEO="ext4"
FS_BOOT="ext2"

# Sollen die vorhandenen Einstellungen des alten Systems gesichert und uebernommen werden ?
DO_BACKUP=1
DO_MIGRATE=1

# /tmp /usr/src und /usr/local/src auf system oder data ?
# Falls system part < 10 GB gehts automatisch auf data
TMPSRC_ON_SYS=1
TMPSRC_SYS_LIMIT=20000
TMPSRC_DIRS="opt usr/portage usr/src usr/local/src tmp var"


########################################
### ab hier nichts mehr aendern
########################################

BACKUP_DONE=0
CREATE_BOOTPART=0

# Log-Datei
LOG_FILE="/install.log"
PART_TABLE=""
EXEC_RC=0

SYSTEM_DISK=""
VIDEO_DISK=""
BOOT_PART=""
SWAP_PART=""
SYSTEM_PART=""
VIDEO_PART=""
EFI_PART=""

PART_DONE=0

#BOOTMAN="LILO"

#fuer die Optik
NUM_PACKAGES=0
ACT_PACKAGE=0
CHOOSEN_PART=""

PT="msdos"

EXEC_RC=0

log() {
   echo "$(date +"%y%m%d %T") <$*>" >> $LOG_FILE
}

msgKey() {
   if [ "$MP_AUTO_INST" != "1" ] ; then
      APP_STR=" - Enter"
   else
      APP_STR=""
   fi
   echo ""
   echo -e "\007"
   echo -e "\033[44;37m$1$APP_STR\033[0m"
   log "$@"
   if [ "$MP_AUTO_INST" != "1" ] ; then
      read
   else
      sleep 2
   fi
}

msgInfo() {
   echo ""
   echo -e "\007"
   echo -e "\033[44;37m$1 ...\033[0m"
   log "$@"
   sleep 2
}

execCmd() {
   if [ "$2" = "" ] ; then
      log "$1"
      echo "Exec <$1>"
      $1 2>&1 | tee -a $LOG_FILE
   else
      log "$1 | $2"
      echo "Exec <$1 | $2>"
      $1 | $2 2>&1 | tee -a $LOG_FILE
   fi
   EXEC_RC=$?
   log "RC: $EXEC_RC"
   [ "$EXEC_RC" != "0" ] && echo "RC <$EXEC_RC>"
   sleep 1
}

unpackArchive() {
   ACT_PACKAGE=$((ACT_PACKAGE+1))
   msgInfo "Entpacke $1 (Paket $ACT_PACKAGE von $NUM_PACKAGES)"
   BL="/tmp/$(basename "$1")"
   [ -f "$BL" ] && rm -f "$BL"
   if [ "$2" != "" ] ; then
      TGT=$2
   else
      TGT=/mnt
   fi
   tar -C $TGT -xJvf "$1" >"${BL}.log" 2>"${BL}.err"
   rc=$?
   cat "${BL}.err" | tee -a $LOG_FILE
   if [ "$rc" != "0" ] ; then
      cat "${BL}.log" >> $LOG_FILE
      echo "Installation abgebrochen"
      log "Installation abgebrochen"
      exit
   fi
   sleep 1
}

autoPart() {
   clear
   CD=$(pwd)
   ACT_DISK=$(df "$CD"|grep "^/dev")
   if [ "${ACT_DISK//*SYSTEM_DISK*/}" = "" ] ; then
      msgKey "Die aktive Partition kann nicht neu partitioniert werden"
      return 0
   fi
   if [ "$MP_AUTO_INST" != "1" ] ; then
      if [ -e /sys/firmware/efi ] ; then
         dialog --title "" --yesno "EFI Boot verwenden ?" 5 25
         if [ "$?" == "0" ] ; then
            EFI_PART="${SYSTEM_DISK}1"
            #CREATE_BOOTPART=1
            PT="gpt"
         fi
      fi
      if [ "$EFI_PART" == "" ] ; then
         dialog --title "" --yesno "Separate BootPartition anlegen ?" 5 36
         [ "$?" == "0" ] && CREATE_BOOTPART=1
         dialog --title "" --defaultno --yesno "GPT anstelle von MBR verwenden ?" 5 36
         [ "$?" == "0" ] && PT="gpt"
      fi
   fi
   echo ""
   echo -e "\033[44;37mCtrl + C bricht ab !\033[0m"
   echo ""

   DISKS="$SYSTEM_DISK"
   if [ "$VIDEO_DISK" != "$SYSTEM_DISK" ] && [ "$VIDEO_PART" == "" ] ; then
      DISKS="$DISKS und $VIDEO_DISK"
   fi
   i=10
   for i in 10 9 8 7 6 5 4 3 2 1 ; do
      echo -e "\033[5;47;31mAlle Partitionen auf $DISKS werden in $i Sekunde(n) neu angelegt !!!\033[0m"
      echo -e "\007"
      sleep 1
   done
   SDEV="/dev/${SYSTEM_DISK}"
   sleep 3
   execCmd "dd if=/dev/zero of=$SDEV bs=1024 count=1"
   execCmd "hdparm -z $SDEV"
   execCmd "parted -s $SDEV mklabel $PT"

   DS=$(cat /sys/block/${SYSTEM_DISK}/size)
   DSIZE=$((DS/2048))
   PART_DONE=1
   BOOT_PART=""

   if [ "$EFI_PART" != "" ] ; then
      execCmd "parted -a opt -s $SDEV mkpart ESI fat32 1 $BOOT_PART_SIZE"
      START=$BOOT_PART_SIZE
      PNUM=2
   elif [ "$CREATE_BOOTPART" == "1" ] ; then
      execCmd "parted -a opt -s $SDEV mkpart primary $FS_BOOT 1 $BOOT_PART_SIZE"
      BOOT_PART="${SYSTEM_DISK}1"
      START=$BOOT_PART_SIZE
      PNUM=2
   else
      START=1
      PNUM=1
   fi
   SYSTEM_PART="${SYSTEM_DISK}${PNUM}"

   if [ "$SYSTEM_DISK" == "$VIDEO_DISK" ] ; then
      if [ $DSIZE -gt $((SYSTEM_PART_SIZE + SWAP_PART_SIZE))  ] ; then
         execCmd "parted -a opt -s $SDEV mkpart primary ext4 $START $SYSTEM_PART_SIZE"
         P_END=$((SYSTEM_PART_SIZE + SWAP_PART_SIZE))
         execCmd "parted -a opt -s $SDEV mkpart primary linux-swap $SYSTEM_PART_SIZE $P_END"
         execCmd "parted -a opt -s $SDEV -- mkpart primary ext4 $P_END -1"
         SWAP_PART="${SYSTEM_DISK}$((PNUM+1))"
         VIDEO_PART="${SYSTEM_DISK}$((PNUM+2))"
      else
         execCmd "parted -a opt -s $SDEV -- mkpart primary ext4 $START -1"
      fi
   else
      if [ $DSIZE -gt $((SYSTEM_PART_SIZE + SWAP_PART_SIZE))  ] ; then
         execCmd "parted -a opt -s $SDEV -- mkpart primary ext4 $START -$SWAP_PART_SIZE"
         execCmd "parted -a opt -s $SDEV -- mkpart primary linux-swap -$SWAP_PART_SIZE -1"
         SWAP_PART="${SYSTEM_DISK}$((PNUM+1))"
      else
         execCmd "parted -a opt -s $SDEV -- mkpart primary ext4 $START -1"
      fi
      if [ "$VIDEO_PART" == "" ] ; then
         PART_DONE=2
         VDEV="/dev/${VIDEO_DISK}"
         execCmd "dd if=/dev/zero of=$VDEV bs=1024 count=1"
         execCmd "parted -s $VDEV mklabel $PT"
         execCmd "parted -a opt -s $VDEV mkpart primary linux-swap 1 $SWAP_PART_SIZE"
         execCmd "parted -a opt -s $VDEV -- mkpart primary linux-swap $SWAP_PART_SIZE -1"
         SWAP_PART="${VIDEO_DISK}1"
         VIDEO_PART="${VIDEO_DISK}2"
         execCmd "hdparm -z $VDEV"
      fi
   fi
   execCmd "hdparm -z $SDEV"
   execCmd "sync"
   sleep 5
}

choosePartition() {
   rm -rf /tmp/ip.* > /dev/null 2>&1
   CHOOSEN_PART=""
   NP=0
   for i in $PART_TABLE ; do
      PSIZE="${i#*_}"
      PNAME="${i%_*}"
      DOIT=0
      if [ "$1" = "System" ] ; then
         INV_PARTS="$EFI_PART xyz"
         if [ "${PNAME//${SYSTEM_DISK}*/}" == "" ] && [ "${INV_PARTS//*${PNAME}*/}" != "" ] && [ $PSIZE -ge $SYS_MINSIZE ] ; then
            DOIT=1
         fi
      elif [ "$1" = "Video" ] ; then
         INV_PARTS="$SYSTEM_PART $EFI_PART $BOOT_PART $SWAP_PART xyz"
         if [ "${PNAME//${VIDEO_DISK}*/}" == "" ] && [ "${INV_PARTS//*${PNAME}*/}" != "" ] && [ $PSIZE -ge $VID_MINSIZE ] ; then
            DOIT=1
         fi
      elif [ "$1" = "Boot" ] ; then
         INV_PARTS="$SYSTEM_PART $EFI_PART $VIDEO_PART $SWAP_PART xyz"
         if [ "${PNAME//*${SYSTEM_DISK}*/}" == "" ] && [ "${INV_PARTS//*${PNAME}*/}" != "" ] && [ $PSIZE -ge $BOOT_MINSIZE ] ; then
            DOIT=1
         fi
      elif [ "$1" = "Swap" ] ; then
         INV_PARTS="$SYSTEM_PART $EFI_PART $VIDEO_PART $BOOT_PART xyz"
         if [ "${PNAME//*${SYSTEM_DISK}*/}" == "" -o "${PNAME//*${VIDEO_DISK}*/}" == "" ] && [ "${INV_PARTS//*${PNAME}*/}" != "" -a $PSIZE -ge $SWAP_MINSIZE ] ; then
            DOIT=1
         fi
      fi
      if [ "$DOIT" == "1" ] ; then
         printf "\"${PNAME}\" \"%8d MB\" " $PSIZE >> /tmp/ip.tmp1
         NP=$((NP+1))
      fi
   done

   if [ $NP -ge 1 ] ; then
      if [ "$1" != "System" ] ; then
         echo -n "\"Keine $1-Partition\" \"\" " >> /tmp/ip.tmp1
         NP=$((NP + 1))
      fi
      {
       echo "dialog --backtitle \"VDR Installationsprogramm\" --title \"$1-Partition waehlen\" \\"
       echo "  --menu '' $((NP+4)) 0 0 \\"
       cat /tmp/ip.tmp1
       echo " 2>/tmp/menu.tmp"
       echo "if [ \"\$?\" != \"0\" ] ; then"
       echo "   rm -f /tmp/menu.tmp"
       echo "fi"
      } >/tmp/ip.tmp

      clear
      rm -f /tmp/menu.tmp
      bash /tmp/ip.tmp

      if [ -s /tmp/menu.tmp ] ; then
         CHOOSEN_PART=$(grep -v "Keine" /tmp/menu.tmp)
      fi
   fi
   log "choosePart: $1-$CHOOSEN_PART-"
}

getAllParts() {
   readPartitions
   choosePartition "System"
   SYSTEM_PART=$CHOOSEN_PART
   choosePartition "Video"
   VIDEO_PART=$CHOOSEN_PART
   if [ "$EFI_PART" == "" ] ; then
      choosePartition "Boot"
      BOOT_PART=$CHOOSEN_PART
   fi
   choosePartition "Swap"
   SWAP_PART=$CHOOSEN_PART
   if checkAllParts ; then
      log "Partitionierung ungueltig"
   else
      MENU_TEXT=""
      for i in $PART_TABLE ; do
         PS="${i#*_}"
         PN="${i%_*}"
         if [ "$PN" == "$BOOT_PART" ] ; then
            PNAME="- Boot"
         elif [ "$PN" == "$SYSTEM_PART" ] ; then
            PNAME="- System"
            if [ "$BOOT_PART" = "" ] ; then
               PNAME="${PNAME}+Boot"
            fi
            if [ "$VIDEO_PART" = "" ] ; then
               PNAME="${PNAME}+Video"
            fi
         elif [ "$PN" == "$SWAP_PART" ] ; then
            PNAME="- Swap"
         elif [ "$PN" == "$VIDEO_PART" ] ; then
            PNAME="- Video"
         else
            PNAME=""
         fi
         if [ "$PNAME" != "" ] ; then
            MENU_TEXT="$MENU_TEXT\\n${PN} $(printf %8d $PS) $PNAME"
         fi
      done
      dialog --title "Partitionierung uebernehmen ?" --yesno "$MENU_TEXT" 0 0
      [ "$?" == "0" ] && return 1
   fi
   return 0
   #echo "$SYS - $BOOT - $VID - $SWAP"
   #echo "$ALL_PARTS"
}

checkAllParts() {
   if [ "$SYSTEM_PART" != "" ] ; then
      if [ "$VIDEO_PART" != "" ] || [ "$VIDEO_DISK" == "$SYSTEM_DISK" ] ; then
         return 1
      fi
   fi
   return 0
}

findDisks() {
   rm -rf /tmp/ip.* > /dev/null 2>&1
   echo "dialog --backtitle 'VDR Installationsprogramm' --title 'System-Platte auswaehlen' \\" > /tmp/ip.tmp
   FOUND_DISKS="$(grep -H 0 /sys/block/sd?/ro | cut -f 4 -d "/")"
   ALL_DISKS=""
   COUNT_DISKS=0
   for i in $FOUND_DISKS ; do
      if [ "$(mount | grep "/dev/$i")" != "" ] ; then
         msgKey "Disk ${i} wird gerade benutzt"
         continue
      fi
      DS=$(cat "/sys/block/${i}/size")
      DISK_SIZE=$((DS/2048))
      if [ $DISK_SIZE -ge $SYS_MINSIZE ] ; then
         if [ "$ALL_DISKS" = "" ] ; then
            ALL_DISKS="${i}"
            SYSTEM_DISK="${i}"
            for j in /dev/${i}[0-9] ; do
               if [ -e "$j" ] ; then
                  mount "$j" /mnt >/dev/null 2>&1
                  if [ "$SYSTEM_PART" == "" ] || [ -d /mnt/_config ] ; then
                     SYSTEM_PART=${j##*/}
                  elif [ "$SYSTEM_PART" != "" ] && [ "$VIDEO_PART" == "" ] && [ -d /mnt/video ] && [ "$(readlink /mnt/video)" == "" ] ; then
                     VIDEO_PART=${j##*/}
                     VIDEO_DISK="${i}"
                  fi
                  if [ "$BOOT_PART" == "" ] && [ -e /mnt/bzImage-act ] ; then
                     BOOT_PART=${j##*/}
                  fi
                  umount /mnt >/dev/null 2>&1
               fi
            done
         else
            ALL_DISKS="$ALL_DISKS ${i}"
            if [ "$VIDEO_DISK" = "" ] ; then
               VIDEO_DISK="${i}"
               for j in /dev/${i}[0-9] ; do
                  if [ -e "$j" ] ; then
                     mount "$j" /mnt >/dev/null 2>&1
                     if [ "$VIDEO_PART" == "" ] || [ -d /mnt/video ] ; then
                        VIDEO_PART=${j##*/}
                     fi
                     umount /mnt >/dev/null 2>&1
                  fi
               done
            fi
         fi
         echo "\"$i\" \"$DISK_SIZE MB\" \\" >>/tmp/ip.tm1
         COUNT_DISKS=$((COUNT_DISKS + 1))
      else
         msgKey "Disk ${i} ist zu klein ($DISK_SIZE < $SYS_MINSIZE)"
      fi
   done
   if [ $COUNT_DISKS -ge 2 ] && [ "$MP_AUTO_INST" != "1" ] ; then
      LN=$((COUNT_DISKS + 6))

      echo "Disks: < $ALL_DISKS >"
      {
       echo "  --menu '' $LN 40 $COUNT_DISKS \\"
       cat /tmp/ip.tm1
       echo " 2>/tmp/menu.tmp"
       echo "if [ \"\$?\" != \"0\" ] ; then"
       echo "   rm -f /tmp/menu.tmp"
       echo "fi"
      } >/tmp/ip.tmp

      rm -f /tmp/menu.tmp
      bash /tmp/ip.tmp

      if [ -s /tmp/menu.tmp ] ; then
         SYSTEM_DISK=$(cat /tmp/menu.tmp)
         rm -f /tmp/menu.tmp
         sed -i /tmp/ip.tmp -e "s/System-Platte/Video-Platte/"
         if [ "$VIDEO_DISK" != "" ] ; then
            sed -i /tmp/ip.tmp -e "s/--menu/--default-item $VIDEO_DISK --menu/"
         fi
         bash /tmp/ip.tmp
         if [ -s /tmp/menu.tmp ] ; then
            VIDEO_DISK=$(cat /tmp/menu.tmp)
         fi
      fi
   else
      [ "$VIDEO_DISK" = "" ] && VIDEO_DISK=$SYSTEM_DISK
   fi
   log "VD: $VIDEO_DISK - SD: $SYSTEM_DISK -"
   log "VP: $VIDEO_PART - SP: $SYSTEM_PART - BP: $BOOT_PART - SW: $SWAP_PART -"
   if [ "$VIDEO_DISK" = "" ] ; then
      return 0
   fi
   return 1
}

checkPrereq() {
   if [ "$(grep "^flags" /proc/cpuinfo | grep " pni")" = "" ] ; then
      dialog --defaultno --yesno "CPU wird nicht unterstuetzt - Installation fortsetzen ?" 5 60
      return $?
   fi
   return 1
}

doPart() {
   if [ "$MP_AUTO_INST" = "1" ] ; then
      if [ "$VIDEO_DISK" == "$SYSTEM_DISK" ] && [ "$VIDEO_PART" != "" ] ; then
         return 1
      else
         autoPart
      fi
   else
      while getAllParts ; do
         dialog --title "" --yesno "Soll neu partitioniert werden ?" 5 35
         if [ "$?" == "0" ] ; then
            if [ "$VIDEO_DISK" != "$SYSTEM_DISK" ] && [ "$VIDEO_PART" != "" ] ; then
               dialog --title "" --yesno "Soll die Video-Disk neu partitioniert werden ?" 5 50
               [ "$?" = "0" ] && VIDEO_PART=""
            fi
            autoPart
         elif [ "$?" != "1" ] ; then
            break
         fi
         SYSTEM_PART=""
         VIDEO_PART=""
         SWAP_PART=""
         BOOT_PART=""
      done
   fi
   if checkAllParts ; then
      msgKey "Partitionierung ungueltig"
      return 0
   fi
   return 1
}

readPartitions() {
   execCmd "hdparm -z /dev/${SYSTEM_DISK}"
   execCmd "sync"
   PART_TABLE=""
   rm -f /tmp/.pt
   grep " [a-z][a-z][a-z][1-9]\$" /proc/partitions | tr -s " " | cut -f 4,5 -d " " | while read -r i ; do
      if [ "${i/*$VIDEO_DISK*/}" == "" ] || [ "${i/*$SYSTEM_DISK*/}" == "" ] ; then
         PART_TABLE="${PART_TABLE}${i#* }_$((${i%% *}/1024)) "
         echo "$PART_TABLE" > /tmp/.pt
      fi
   done
   PART_TABLE=$(cat /tmp/.pt)
   log "PT: <$PART_TABLE>"
}

doFormat() {
   if [ "$PART_DONE" = "0" ] && [ "$DO_BACKUP" = "1" ] && [ "$SYSTEM_PART" != "$VIDEO_PART" ] ; then
      execCmd "mount /dev/$SYSTEM_PART /mnt"
      if [ -d /mnt/etc ] ; then
         mkdir /bkp
         execCmd "mount /dev/$VIDEO_PART /bkp"
         if [ -d /bkp/video ] ; then
            if [ "$MP_AUTO_INST" != "1" ] ; then
               dialog --yesno "Soll die alte Konfiguration gesichert werden ?" 5 55
               if [ $? != 0 ] ; then
                  DO_BACKUP=0
               fi
            else
               if [ -e /bkp/g2v-backup/.do_migrate ] ; then
                  DO_BACKUP=0
                  msgInfo "Backup existiert bereits !"
               fi
            fi
            if [ "$DO_BACKUP" = "1" ] ; then
               if [ -d /bkp/g2v-backup ] ; then
                  execCmd "rm -rf /bkp/g2v-backup/*"
               else
                  mkdir /bkp/g2v-backup
               fi
               msgInfo "Sichere /etc /_config /home und /root nach /g2v-backup auf $VIDEO_PART"

               if [ ! -d /bkp/g2v-backup/etc ] ; then
                  execCmd "cp -af /mnt/etc /bkp/g2v-backup"
                  BACKUP_DONE=1
               fi
               if [ ! -d /bkp/g2v-backup/_config ] ; then
                  execCmd "cp -af /mnt/_config /bkp/g2v-backup"
                  BACKUP_DONE=1
               fi
               if [ ! -d /bkp/g2v-backup/home ] ; then
                  execCmd "cp -af /mnt/home /bkp/g2v-backup"
                  BACKUP_DONE=1
               fi
               if [ ! -d /bkp/g2v-backup/root ] ; then
                  execCmd "cp -af /mnt/root /bkp/g2v-backup"
                  BACKUP_DONE=1
               fi
            fi
         fi
         execCmd "umount /dev/$VIDEO_PART"
      fi
      execCmd "umount /dev/$SYSTEM_PART"
   fi

   if [ "$EFI_PART" != "" ] ; then
      msgInfo "Formatiere EFI Boot-Partition ${SYSTEM_DISK}1 mit vfat ..."
      execCmd "mkfs.vfat -F 32 /dev/${EFI_PART}"
      execCmd "parted -s /dev/${SYSTEM_DISK} set ${SYSTEM_PART#*$SYSTEM_DISK} boot on"
   elif [ "$BOOT_PART" != "" ] ; then
      msgInfo "Formatiere Boot-Partition $BOOT_PART mit $FS_BOOT ..."
      execCmd "mke2fs -t $FS_BOOT /dev/$BOOT_PART"
      execCmd "tune2fs -i 0 -c 0 /dev/$BOOT_PART"
      execCmd "parted -s /dev/${SYSTEM_DISK} set ${BOOT_PART#*$SYSTEM_DISK} boot on"
   else
      execCmd "parted -s /dev/${SYSTEM_DISK} set ${SYSTEM_PART#*$SYSTEM_DISK} boot on"
   fi
   execCmd "hdparm -z /dev/${SYSTEM_DISK}"
   execCmd "sync"
   msgInfo "Formatiere System-Partition $SYSTEM_PART mit $FS_ROOT ..."
   execCmd "mke2fs -t $FS_ROOT /dev/$SYSTEM_PART"
   execCmd "tune2fs -i 0 -c 0 /dev/$SYSTEM_PART"

   if [ "$SWAP_PART" == "" ] && [ "$MP_AUTO_INST" == "1" ] ; then
      SP="$(parted -s "/dev/${SYSTEM_DISK}" print|grep -m 1 "^ [0-9] .*swap"|cut -b 2)"
      SWP=""
      if [ "$SP" == ""  ] && [ "$SYSTEM_DISK" != "$VIDEO_DISK" ] ; then
         SP="$(parted -s "/dev/${VIDEO_DISK}" print|grep -m 1 "^ [0-9] .*swap"|cut -b 2)"
         [ "$SP" != "" ] && SWP="${VIDEO_DISK}${SP}"
      else
         [ "$SP" != "" ] && SWP="${SYSTEM_DISK}${SP}"
      fi
      if [ "$SWP" != "" ] ; then
         if [ "$SYSTEM_PART" != "$SWP" ] && [ "$VIDEO_PART" != "$SWP" ] && [ "$BOOT_PART" != "$SWP" ] ; then
            SWAP_PART=$SWP
         fi
      fi
   fi
   if [ "$SWAP_PART" != "" ] ; then
      msgInfo "Ernenne $SWAP_PART zur Swap-Partition"
      execCmd "mkswap /dev/$SWAP_PART"
      sleep 3
   fi

   if [ "$VIDEO_PART" == "" ] ; then
      return 1
   fi

   if [ "$PART_DONE" != "2" ] ; then
      execCmd "mount /dev/$VIDEO_PART /mnt"
      FSV=$(mount | grep "/dev/$VIDEO_PART " | head -n 1 | cut -f 5 -d " ")
      umount /mnt >/dev/null 2>&1
      if [ "$FSV" != "" ] ; then
#         FS_VIDEO=$FSV
         SYS_DISK=$(df "$INSTALL_DIR"|grep "^/dev")
         if [ "${SYS_DISK//*$SYSTEM_DISK*/}" = "" ] ; then
            FS_VIDEO=$FSV
            msgKey "Die Installations-Partition wird nicht neu formatiert"
            return 1
         fi
      fi
   else
      FSV=""
   fi
   if [ "$FSV" != "" ] && [ "$MP_AUTO_INST" != "1" ] ; then
      dialog --title " Videos erhalten ? " --yesno "Soll die Video-Partition mit $FSV beibehalten werden ? Ansonsten wird diese mit ext4 neu formatiert" 6 58
      [ "$?" != "0" ] && FSV=""
   fi
   if [ "$FSV" == "" ] ; then
      echo "Formatiere Video-Partition $VIDEO_PART mit $FS_VIDEO ..."
      execCmd "mke2fs -t $FS_VIDEO /dev/$VIDEO_PART"
      execCmd "tune2fs -i 0 -c 0 /dev/$VIDEO_PART"
   else
      FS_VIDEO=$FSV
   fi

   return 1
}

doInstall() {
   if [ "$MP_AUTO_INST" != "1" ] ; then
      APP_STR=" - Enter"
   else
      APP_STR=""
   fi

   umount /mnt >/dev/null 2>&1
   umount /mnt >/dev/null 2>&1

   # System und Boot partition mounten:
   execCmd "mount -t $FS_ROOT /dev/$SYSTEM_PART /mnt"
   [ "$EXEC_RC" != "0" ] && return 0
   if [ "$BOOT_PART" != "" ] ; then
      execCmd "mkdir -p /mnt/boot"
      execCmd "mount /dev/$BOOT_PART /mnt/boot"
      [ "$EXEC_RC" != "0" ] && return 0
   fi


   while [ ! -f "$INSTALL_DIR/g2v_root.tar.xz" ] ; do
      umount "$INSTALL_DEVICE" > /dev/null 2>&1
      eject "$INSTALL_DEVICE"
      msgInfo "Installations-Disk wieder einlegen"
      if [ "$MP_AUTO_INST" = "1" ] ; then
         sleep 10
      fi
      mount "$INSTALL_DEVICE" "$INSTALL_DIR" 2>/dev/null
   done

   NUM_PACKAGES=$(($(ls $INSTALL_DIR/g2v_*.tar.xz | wc -w)))
   unpackArchive "$INSTALL_DIR/g2v_root.tar.xz"
   unpackArchive "$INSTALL_DIR/g2v_boot.tar.xz"
   unpackArchive "$INSTALL_DIR/g2v_config.tar.xz"

   TARGET=/mnt
   DT=$(date +%Y%m%d)
   cp -f "$INSTALL_DIR/HISTORY" "/mnt/HISTORY.$DT"
   cp -f "$INSTALL_DIR/README" "/mnt/README.$DT"

   MM_DIRS="video audio pictures film games"

   ln -s everything/current /mnt/log/messages > /dev/null 2>&1
   chmod 777 /mnt/tmp/* /mnt/log/* > /dev/null 2>&1
   touch /mnt/log/lastlog > /dev/null 2>&1

   if [ "$VIDEO_PART" != "" ] ; then
      execCmd "mkdir -p /mnt/mnt/data"
      execCmd "mount -t $FS_VIDEO /dev/$VIDEO_PART /mnt/mnt/data"
      SS="$(grep "${SYSTEM_PART}$" /proc/partitions)"
      SS="${SS% *}"
      SYS_SIZE=${SS##* }
      if [ $((SYS_SIZE/1024)) -le $TMPSRC_SYS_LIMIT ] ; then
         TMPSRC_ON_SYS=0
         TARGET=/mnt/mnt/data/system
         rm -rf "${TARGET}"
         mkdir -p "$TARGET"
         for i in $TMPSRC_DIRS ; do
            rm -rf "/mnt/$i"
            mkdir -p "${TARGET}/$i" "/mnt/$i"
            execCmd "mount --bind ${TARGET}/$i /mnt/$i"
#            ln -s /mnt/data/system/${i} /mnt/${i}
         done
         chown portage:portage /mnt/mnt/data/system/usr/portage 2>/dev/null
      fi
      for i in $MM_DIRS ; do
         mkdir "/mnt/mnt/data/${i}" >/dev/null 2>&1
         if [ "$(readlink "/mnt/${i}")" == "" ] ; then
            rm -rf "/mnt/${i}"
         else
            rm "/mnt/${i}"
         fi
         ln -s "mnt/data/${i}" "/mnt/${i}" >/dev/null 2>&1
         rm -f "/mnt/mnt/data/${i}/DISC" "/mnt/mnt/data/${i}/USB" "/mnt/mnt/data/${i}/MEDIA" >/dev/null 2>&1
         if [ "$i" != "video" ] ; then
            ln -s /media/dvd "/mnt/mnt/data/${i}/DISC" >/dev/null 2>&1
            ln -s /media "/mnt/mnt/data/${i}/MEDIA" >/dev/null 2>&1
         fi
      done
   else
      for i in $MM_DIRS ; do
         rm "/mnt/${i}" >/dev/null 2>&1
         mkdir "/mnt/${i}" >/dev/null 2>&1
         if [ "$i" != "video" ] ; then
            ln -s ../media/dvd "/mnt/${i}/DISC" >/dev/null 2>&1
            ln -s ../media "/mnt/${i}/MEDIA" >/dev/null 2>&1
         fi
      done
      rm /mnt/tmp >/dev/null 2>&1
      mkdir /mnt/tmp >/dev/null 2>&1
   fi

   unpackArchive "$INSTALL_DIR/g2v_src.tar.xz" $TARGET
   unpackArchive "$INSTALL_DIR/g2v_optvar.tar.xz" $TARGET

   if [ ! -e /mnt/_config/update/.restored ] ; then
      msgInfo "fstab anpassen"
      echo "/dev/cdrom      /media/dvd      auto    ro,noauto,user 0 0" > /mnt/etc/fstab
      NLINE="/dev/${SYSTEM_PART}   /   ${FS_ROOT}   noatime,user_xattr 1 1"
      echo "$NLINE" >> /mnt/etc/fstab
      if [ "$VIDEO_PART" != "" ] ; then
         NLINE="/dev/${VIDEO_PART}   /mnt/data   ${FS_VIDEO}   noatime 1 2"
         echo "$NLINE" >> /mnt/etc/fstab
      fi
      if [ "$SWAP_PART" != "" ] ; then
         NLINE="/dev/${SWAP_PART}   none   swap   sw 0 0"
         echo "$NLINE" >> /mnt/etc/fstab
      fi
      if [ "$BOOT_PART" != "" ] ; then
         NLINE="/dev/${BOOT_PART}   /boot   $FS_BOOT   noatime 1 2"
         echo "$NLINE" >> /mnt/etc/fstab
      fi
      if [ "$SYSTEM_DISK" != "sda" ] && [ "$MP_AUTO_INST" != "1" ] ; then
         if [ "$(grep "1" "/sys/block/${SYSTEM_DISK}/removable")" != "" ] && [ "$(grep "1" /sys/block/sda/removable)" != "" ] ; then
            msgInfo "Aendere root von $SYSTEM_DISK auf sda"
            sed -i /mnt/etc/fstab -e "s%${SYSTEM_DISK}%sda%"
         fi
      fi
      if [ "$TMPSRC_ON_SYS" == "0" ] ; then
         TARGET=/mnt/data/system
         for i in $TMPSRC_DIRS ; do
            NLINE="${TARGET}/$i   /$i   none  bind  0 0"
            echo "$NLINE" >> /mnt/etc/fstab
         done
      fi
      cp -af /mnt/_config/install/vdr/* /mnt/etc/vdr/
   fi

   rm -f /mnt/mnt/data/portage/packages/g2v.pkg /mnt/_config/update/g2v_md5_fixes > /dev/null 2>&1
   if [ -d "${INSTALL_DIR}/g2v_inst" ] ; then
      msgInfo "Installationsdateien kopieren"
      execCmd "cp -avf ${INSTALL_DIR}/g2v_inst/* /mnt/"

      for i in /mnt/*.tar.bz2 ; do
         if [ -f "$i" ] ; then
            execCmd "tar -C /mnt -xjvf $i"
         fi
      done

      # updates entpacken
      MD5_FILE="${INSTALL_DIR}/g2v_inst/_config/update/g2v_md5_fixes"
      if [ -f "$MD5_FILE" ] ; then
         grep "\.tar\.bz2" "$MD5_FILE" | cut -f 3 -d " " | while read -r i ; do
            execCmd "tar -C /mnt -xjvf /mnt/_config/update/$i"
         done
      fi
      rm -f /mnt/*.tar.bz2 > /dev/null 2>&1

      # Check for packages to install
      if [ -e "${INSTALL_DIR}/g2v_inst/mnt/data/portage/packages/All" ] ; then
         cd "${INSTALL_DIR}/g2v_inst/mnt/data/portage/packages/All"
         ls ./*-*/*.tbz2 | sed -e "s/\.tbz2.*//" > /mnt/mnt/data/portage/packages/g2v.pkg
         cd /
      fi
   fi
   if [ -d /mnt/mnt/data/g2v-backup ] ; then
      if [ "$BACKUP_DONE" = "1" ] && [ ! -e /mnt/_config/update/.restored ] && [ "$DO_MIGRATE" = "1" ] ; then
         touch /mnt/mnt/data/g2v-backup/.do_migrate
      else
         rm -f /mnt/mnt/data/g2v-backup/.do_migrate > /dev/null 2>&1
      fi
   fi
   if [ "$EFI_PART" != "" ] ; then
      execCmd "mkdir /efi"
      execCmd "mount /dev/${SYSTEM_DISK}1 /efi"
      execCmd "mkdir -p /efi/efi/boot"
      execCmd "cp -a $(readlink -f /mnt//boot/bzImage-act) /efi/efi/boot/bootx64.efi"
      execCmd "mount --bind /proc /mnt/proc"
      execCmd "mount --bind /sys /mnt/sys"
      execCmd "mount --bind /dev /mnt/dev"
      chroot /mnt efibootmgr -c -d /dev/sda -p 1 -L Gentoo -l '\efi\boot\bootx64.efi'
      umount /mnt/efi 2>/dev/null
   fi

   umount /mnt/mnt/data 2>/dev/null

   return 1
}

#
#
log "Gen2VDR Installation startet"

#disable screen blanking
echo -en "\033[9;0]"

if [ "$INSTALL_DEVICE" = "" ] ; then
   INSTALL_DEVICE="/dev/sr0"
fi

if [ "$INSTALL_DIR" = "" ] ; then
   INSTALL_DIR="/SETUP"
fi

if checkPrereq ; then
   echo "Installation abgebrochen"
   exit
fi

if [ "$MP_AUTO_INST" != "1" ] ; then
   dialog --backtitle "VDR Installationsprogramm" --title "Jetzt gehts los" --menu \
   "   Installationsmethode auswaehlen" \
    11 60 4 \
   "INTER" "Interaktiv" \
   "AUTO"  "Automatisch ohne separate Boot-Partition"  \
   "AUTO_BOOT"  "Automatisch incl Boot-Partition"  \
   "AUTO_NO_MIG"  "Automatisch ohne Migration" 2> /tmp/menu.tmp

   case $? in
      0)
        ;;
      1)
        exit
        ;;
      255)
        exit
        ;;
   esac
   clear

   menu=$(cat /tmp/menu.tmp)
   rm -f /tmp/menu.tmp

   if [ "$menu" = "AUTO" ]; then
      MP_AUTO_INST=1
   elif [ "$menu" = "AUTO_NO_MIG" ]; then
      MP_AUTO_INST=1
      DO_MIGRATE=0
   elif [ "$menu" = "AUTO_BOOT" ]; then
      MP_AUTO_INST=1
      CREATE_BOOTPART=1
   else
      MP_AUTO_INST=0
   fi
fi

if findDisks ; then
   echo "Installation bei der Platten/CD Erkennung abgebrochen"
   exit
fi

#if [ "$MP_AUTO_INST" != "1" ] ; then
#   dialog --title "" --defaultno --yesno "Grub2 anstelle von Lilo verwenden ?" 5 39
#   [ "$?" == "0" ] && BOOTMAN="GRUB"
#fi

if doPart ; then
   echo "Installation bei Partitionierung abgebrochen"
   exit
fi

if doFormat ; then
   echo "Installation bei Formatierung abgebrochen"
   exit
fi

if doInstall ; then
   execCmd "umount /mnt >/dev/null 2>&1"
   echo "Installation beim Kopieren abgebrochen"
   exit
fi

umount $INSTALL_DEVICE
cp -f $LOG_FILE /mnt/ >/dev/null 2>&1

#if [ "$BOOTMAN" == "GRUB" ] ; then
#   mount -t proc none /mnt/proc
#   mount --rbind /sys /mnt/sys
#   mount --rbind /dev /mnt/dev
#   source /etc/profile
#   export PS1="(chroot) $PS1"
#   export SYSTEM_DISK
#
#   chroot /mnt /bin/bash <<EOF
#   grub2-install --force /dev/${SYSTEM_DISK}
#   grub2-mkconfig -o /boot/grub/grub.cfg
#   exit
#EOF
#else
   LILOCONF="/mnt/etc/lilo.conf"
   cp $LILOCONF $LILOCONF.org
   BOOT_KERNEL="Gen2VDR"
   if [ "$MP_AUTO_INST" != "1" ] ; then
#      dialog --defaultno --yesno "Soll kernel 4.9 aktiviert werden ?" 5 39
#      if [ $? == 0 ] ; then
#         BOOT_KERNEL="G2V-4.09"
#      fi
      dialog --defaultno --yesno "Soll pci=nomsi aktiviert werden ?" 5 38
      if [ $? == 0 ] ; then
         BOOT_KERNEL="${BOOT_KERNEL}-nomsi"
      fi
   fi
   sed -i $LILOCONF -e "s/rootfstype=ext./rootfstype=${FS_ROOT}/" \
                    -e "s/^default = .*/default = ${BOOT_KERNEL}/" \
                    -e "s%^root.*/dev/sd.*%root = /dev/${SYSTEM_PART}%" \
                    -e "s%^boot.*%boot = /dev/${SYSTEM_DISK}%"

   if [ "$SYSTEM_DISK" != "sda" ] && [ "$MP_AUTO_INST" != "1" ] ; then
      if [ "$(grep "1" "/sys/block/${SYSTEM_DISK}/removable")" != "" ] && [ "$(grep "1" /sys/block/sda/removable)" != "" ] ; then
         msgInfo "Aendere root von $SYSTEM_DISK auf sda"
         sed -i $LILOCONF -e "s%${SYSTEM_DISK}%sda%"
      fi
   fi
   ln -s /mnt/boot /
   ln -s /mnt/_config /

   msgInfo "Lilo ausfuehren"
   execCmd "lilo -C $LILOCONF"
#fi

echo ""
if [ ! -e /mnt/_config/update/.restored ] ; then
   echo "Installation erfolgreich beendet !"
   echo "Nach dem Reboot gehts weiter mit Stufe 2"
   for i in vdr g2vgui ; do
      rm /mnt/etc/runlevels/*/$i> /dev/null 2>&1
   done
   ln -s /etc/init.d/local /mnt/etc/runlevels/default/local 2>/dev/null
   mv -f /mnt/etc/local.d/g2v.start /mnt/etc/local.d/g2v.start.org
   mv -f /mnt/etc/local.d/g2v.stop /mnt/etc/local.d/g2v.stop.org
   echo "/_config/install/g2v_install.sh" > /mnt/etc/local.d/g2vinit.start
   chmod +x /mnt/etc/local.d/g2vinit.start
else
   echo "Restore erfolgreich beendet !"
fi
echo ""
echo "Das Passwort fuer den root-user lautet: <gen2vdr>"

if [ "$INSTALL_DEVICE" != "" ] && [ "$(blkid $INSTALL_DEVICE)" != "" ] ; then
   eject $INSTALL_DEVICE
   msgKey "Das System wird nun neu gestartet - Disk entfernen"

   if [ "$MP_AUTO_INST" = "1" ] ; then
      sleep 10
   fi
   sleep 2

   if [ "$(blkid $INSTALL_DEVICE)" != "" ] ; then
      eject $INSTALL_DEVICE
      msgInfo "Bitte CD entfernen und neustarten oder Enter"
      read
   fi
else
   msgKey "Das System wird nun neu gestartet"
fi
cp -f $LOG_FILE /mnt/ >/dev/null 2>&1
echo "Rebooting" >> /mnt/$LOG_FILE

reboot
