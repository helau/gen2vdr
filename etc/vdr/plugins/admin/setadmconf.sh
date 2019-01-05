#!/bin/bash
source /etc/vdr.d/conf/gen2vdr.cfg

VDR_CONF="/etc/vdr.d/conf/vdr"

[ "$1" != "" ] && [ -f $1 ] && VDR_CONF=$1
[ "$2" != "" ] && [ -f $2 ] && ADMIN_CFG_FILE=$2

sh /etc/vdr/plugins/admin/setvdrconf.sh $ADMIN_CFG_FILE $VDR_CONF.old > /dev/null 2>&1

diff ${VDR_CONF}.old $VDR_CONF | grep "^> [A-Z]" | while read i ; do
   VAR=${i/=*/}
   VAL=${i/*=/}
   $SETVAL ${VAR:2} "${VAL//\"/}" $ADMIN_CFG_FILE $VDR_CONF
done
