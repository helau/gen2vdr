#!/bin/bash
echo ""
echo "mkboot start"

TARGET_DIR="${TARGET_DIR:=/mnt/data/backup}"
XZ_OPTS=${XZ_OPTS:="-2"}
TAR_OPTS=${TAR_OPTS:="-cJpf"}

cd /

rm -f ${TARGET_DIR}/g2v_boot.tar.xz

export XZ_OPT=$XZ_OPTS

tar $TAR_OPTS ${TARGET_DIR}/g2v_boot.tar.xz ./boot

echo "mkboot end"
echo ""
