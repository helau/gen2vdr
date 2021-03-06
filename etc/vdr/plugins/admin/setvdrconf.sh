#!/bin/bash
source /_config/bin/g2v_funcs.sh

VDR_CONF="/etc/vdr.d/conf/vdr"

[ "$1" != "" ] && [ -f $1 ] && ADMIN_CFG_FILE=$1
[ "$2" != "" ] && [ -f $2 ] && VDR_CONF=$2

echo "# This file is generated by the admin Plugin" >${VDR_CONF}.new
echo "# Dont change it unless you know what you are doing" >>${VDR_CONF}.new
echo "" >>${VDR_CONF}.new

grep "^/" $ADMIN_CFG_FILE | grep -v ":PLG_" | sed -e "s/\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):/# \7 \(\6\)\n\2=\"\3\"\n/" >>${VDR_CONF}.new
PLGS=$(grep ":PLG_" $ADMIN_CFG_FILE | grep -v ":0:I:0" |cut -f 2,3 -d ":" |sort -n -t: -k2| sed -e "s/PLG_//" -e "s/:.*//" | tr "\n" " " | sed -e "s/[ ]*$//")
echo "PLUGINS=\" $PLGS \"" >> ${VDR_CONF}.new

if [ "$1" != "-q" ] ; then
   diff ${VDR_CONF} ${VDR_CONF}.new | grep "^>" | cut -f 2- -d " " | while read i ; do
      [ "$i" != "" ] && glogger -s "Changed <$i> in $VDR_CONF"
   done
fi
cp -vf ${VDR_CONF} ${VDR_CONF}.old
mv -f ${VDR_CONF}.new ${VDR_CONF}
