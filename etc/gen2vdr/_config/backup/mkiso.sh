#!/bin/bash
#http://sourceforge.net/p/systemrescuecd/code/ci/master/tree/buildscripts/recreate-iso.sh#l162
source /etc/g2v-release
G2V_VER="${ID: -2}"
echo ""
echo "mkiso start"
TARGET_DIR="${TARGET_DIR:=/mnt/data/backup}"
[ ! -e $TARGET_DIR ] && mkdir -p $TARGET_DIR

ISOLX_DIR="/_config/backup/isolinux"
INST_DIR="/_config/backup"

TARGET="${TARGET:=$TARGET_DIR/g2v${G2V_VER}_$(date +%y%m%d).iso}"

#for i in ${TARGET_DIR}/g2v_*.tar.xz ; do
#   [ ! -e $i ] && break
#   echo "Checking $i ..."
#   tar -tjcf $i > /tmp/g2v.log 2>&1 
#   if [ "$?" != "0" ] ; then
#      cat /tmp/g2v.log
#      exit
#   fi
#done

PKGS=$(ls $TARGET_DIR/g2v_*.tar.xz)
#set -x
# 2. create memdisk tar image which contains initial embedded grub.cfg
GD=$(date +%y%m%d%H%M)
GRUBCFG="grub-g2v-${GD}.cfg"
TEMPDIR=/tmp/efi
memdisk_dir="/tmp/MEMDISKDIR"
memdisk_img="/tmp/MEMDISKIMG"
rm -rf ${memdisk_dir} ${memdisk_img}

ISODIR=${TEMPDIR}/iso
iso_date=$(date -u +%Y%m%d%H%M%S00)

rm -rf ${TEMPDIR}
mkdir -p ${TEMPDIR}/efi/boot/ ${TEMPDIR}/boot/grub/
cp -a $INST_DIR/setup.sh ${TEMPDIR}/
cp -a $INST_DIR/autorun ${TEMPDIR}/
cp -a $ISOLX_DIR ${TEMPDIR}/
cp -a $ISOLX_DIR/README ${TEMPDIR}/
cp -a $ISOLX_DIR/INSTALL ${TEMPDIR}/
cp -a $ISOLX_DIR/COPYING ${TEMPDIR}/
cp -a $ISOLX_DIR/HISTORY ${TEMPDIR}/
cp -a $INST_DIR/grub/* ${TEMPDIR}/boot/grub/
cp -a /usr/lib64/grub/x86_64-efi ${TEMPDIR}/boot/grub/
mv ${TEMPDIR}/boot/grub/grub.cfg ${TEMPDIR}/boot/grub/${GRUBCFG}

mkdir -p "${memdisk_dir}/boot/grub"
cp -a $ISOLX_DIR ${memdisk_dir}/
initialcfg="${memdisk_dir}/boot/grub/grub.cfg"
echo "" >| ${initialcfg}
echo "search --file --no-floppy --set=root /boot/grub/${GRUBCFG}" >> ${initialcfg}
echo "set prefix=/boot/grub" >> ${initialcfg}
echo "source (\${root})/boot/grub/${GRUBCFG} " >> ${initialcfg}
(cd "${memdisk_dir}"; tar -cf - boot) > "${memdisk_img}"

# 3. create bootx64.efi that contains embedded memdisk tar image
grub-mkimage -m "${memdisk_img}" -o "${TEMPDIR}/efi/boot/bootx64.efi" \
    --prefix='(memdisk)/boot/grub' -d /usr/lib64/grub/x86_64-efi -C xz -O x86_64-efi \
    search iso9660 configfile normal memdisk tar boot linux part_msdos part_gpt \
    part_apple configfile help loadenv ls reboot chain search_fs_uuid multiboot \
    fat iso9660 udf ext2 btrfs ntfs reiserfs xfs lvm ata

# 4. create boot/grub/efi.img that contains bootx64.efi
fatdisk_dir="/tmp/FATDISKDIR"
fatdisk_img="/tmp/FATDISKIMG"
rm -rf ${fatdisk_dir} ${fatdisk_img}
mkdir -p "${fatdisk_dir}/efi/boot"
cp -a "${TEMPDIR}/efi/boot/bootx64.efi" "${fatdisk_dir}/efi/boot/bootx64.efi"
mformat -C -f 1440 -L 16 -i "${TEMPDIR}/boot/grub/efi.img" ::
mcopy -s -i "${TEMPDIR}/boot/grub/efi.img" "${fatdisk_dir}/efi" ::/


rm -v $TARGET
xorriso -as mkisofs -joliet -rock --modification-date=${iso_date} \
        -omit-version-number -disable-deep-relocation \
        -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
        -publisher GEN2VDR -volid GEN2VDR_${G2V_VER} -o ${TARGET} \
        ${PKGS} ${TEMPDIR}

echo "mkiso end"
echo ""
