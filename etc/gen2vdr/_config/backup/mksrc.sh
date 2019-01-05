#!/bin/bash
echo ""
echo "mksrc start"

EXCL=/tmp/mksrc.excl

TARGET_DIR="${TARGET_DIR:=/mnt/data/backup}"
XZ_OPTS=${XZ_OPTS:="-2"}
TAR_OPTS=${TAR_OPTS:="-cJpf"}
export XZ_OPT=$XZ_OPTS

rm -f ${TARGET_DIR}/g2v_src.tar.xz ${TARGET_DIR}/g2v_optvar.tar.xz > /dev/null 2>&1
cd /

{
echo -ne "./var/cache/*/*\n./var/lib/dhcpcd/*\n./var/tmp/*\n./var/lib/mlocate/mlocate.db\n./var/lib/alsa/asound.state\n"
echo -ne "./var/vdr/epg.data\n./var/run/*.socket\n./var/lib/plexmediaserver/*\n./var/nmbd/unexpected\n"
echo -ne "./var/lib/samba/private/msg.sock/*\n"
} >${EXCL}

if [ "$1" != "-b" ] ; then
   echo -ne "./var/lib/mysql/*-bin.00*\n./var/lib/mysql/*-bin.index\n" >>${EXCL}
#   echo -ne "./var/lib/mediatomb/mediatomb.db*\n" >> ${EXCL}
else
   shift
fi
find ./var/log -type f >>$EXCL

tar $TAR_OPTS ${TARGET_DIR}/g2v_optvar.tar.xz --one-file-system  --exclude-from=$EXCL \
    ./opt ./var &

echo -ne "*.rej\n*.orig\n" >${EXCL}2
if [ "$1" != "-k" ] ; then
   echo -ne "*.so\n*.o\n.*.ko\n.*.o.cmd\n.*.ko.cmd\n.tmp_versions\nbzImage\nvmlinux.bin\n" >>${EXCL}2
fi

tar $TAR_OPTS ${TARGET_DIR}/g2v_src.tar.xz --one-file-system  --exclude-from=${EXCL}2 \
    ./usr/src ./usr/local/src ./usr/portage/packages ./usr/portage/profiles

echo "mksrc end"
echo ""
