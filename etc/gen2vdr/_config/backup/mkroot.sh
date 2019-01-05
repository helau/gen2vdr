#!/bin/bash
echo ""
echo "mkroot start"

EXCL=/tmp/mkroot.excl

TARGET_DIR="${TARGET_DIR:=/mnt/data/backup}"
XZ_OPTS=${XZ_OPTS:="-2"}
TAR_OPTS=${TAR_OPTS:="-cJpf"}

chmod +x /usr/bin/* > /dev/null 2>&1
chmod +x /usr/sbin/* > /dev/null 2>&1
chmod +x /bin/* > /dev/null 2>&1
chmod +x /sbin/* > /dev/null 2>&1

eselect env update
ldconfig
depmod -a

cd /

{
echo -ne ".cache/*\n.ccache/*\n./tmp\n./.screen\n./usr/portage/*\n./media/*\n"
echo -ne "*.pid\n./opt\n./usr/src\n./usr/local/src\n./_config\n./etc\n./root\n./home\n./var\n"
echo -ne "./mnt/*\n./audio\n./video\n./pictures\n./film\n./boot\n"
} >${EXCL}

#rm -f /HISTORY* /README* /.autoinst /install.* > /dev/null 2>&1
rm -f ${TARGET_DIR}/g2v_root.tar.xz

if [ "$1" == "-b" ] ; then
   touch /_config/update/.restored
else
   for i in ./* ./.* ; do
      [ ! -d "$i" ] && echo -ne "$i\n" >>${EXCL}
   done
   echo -ne "./video\n./film\n./pictures\n./audio\n./games\n" >>${EXCL}
fi

export XZ_OPT=$XZ_OPTS

tar $TAR_OPTS ${TARGET_DIR}/g2v_root.tar.xz --one-file-system --exclude-from=$EXCL ./

echo "mkroot end"
echo ""
