#!/bin/bash
source /etc/vdr.d/conf/gen2vdr.cfg

VAL=$(grep -m1 ":$1:" $ADMIN_CFG_FILE | cut -f 3 -d ":")
TYPE=$(grep -m1 ":$1:" $ADMIN_CFG_FILE | cut -f 4 -d ":")

#if [ "$TYPE" = "L" ] ; then
#   SET_VAL=$(grep -m1 ":$1:" $ADMIN_CFG_FILE | cut -f 6 -d ":" | cut -f $(($VAL+1)) -d ",")
#else
   SET_VAL=$VAL
#fi

if [ "$2" = "-B" ] ; then
   echo $SET_VAL | sed 's/ //g'
else
   echo $SET_VAL | sed -e 's/^ //g' -e 's/ $//g'
fi
