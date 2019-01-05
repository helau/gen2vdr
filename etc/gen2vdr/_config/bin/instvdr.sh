#!/bin/bash
source /_config/bin/g2v_funcs.sh

#set -x
if [ "$(pidof vdr)" != "" -a "$1" != "-f" ] ; then
   /etc/init.d/vdr stop
   /_config/bin/gg_switch.sh
   RESTART=1
else
   RESTART=0
fi

cd ${VDR_SOURCE_DIR}
[ "$1" == "0" ] && strip --strip-unneeded vdr
rm -f vdr.pc
make install-pc
make install

#rm -rf ${VDR_LIB_DIR}/*
# if Parameter 1 is set to 0 strip libs
[ "$1" == "0" ] && strip --strip-unneeded ${VDR_SOURCE_DIR}/PLUGINS/lib/*
cp -afp ${VDR_SOURCE_DIR}/PLUGINS/lib/* ${VDR_LIB_DIR}/
[ -e ${VDR_SOURCE_DIR}/PLUGINS/src/graphtftng/graphtft-fe/graphtft-fe ] && cp -v ${VDR_SOURCE_DIR}/PLUGINS/src/graphtftng/graphtft-fe/graphtft-fe /usr/local/bin/

[ "$(readlink /etc/vdr/locale)" != "" ] && rm /etc/vdr/locale
cp -au ${VDR_SOURCE_DIR}/locale/* /usr/local/share/locale/

sh /etc/vdr/plugins/admin/cfgplg.sh

if [ "$RESTART" = "1" ] ; then
   /etc/init.d/vdr start
   /_config/bin/gg_switch.sh VDR
fi
