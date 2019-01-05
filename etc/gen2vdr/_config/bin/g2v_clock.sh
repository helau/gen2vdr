#!/bin/bash
source /_config/bin/g2v_funcs.sh
# set to UTC or localtime

CLOCK=$(source /etc/conf.d/hwclock; echo ${clock})

hwc_parms="--noadjfile"
[ "$DIRECTISA" = "1" ] && hwc_parms="$hwc_parms --directisa"

if [ "$CLOCK" = "UTC" ] ; then
   hwc_parms="$hwc_parms --utc"
else
   hwc_parms="$hwc_parms --localtime"
fi

rm -rf /etc/adjtime > /dev/null 2>&1

if [ "$1" = "-set" ] ; then
   cmd="--systohc"
elif [ "$1" = "-get" ] ; then
   cmd="--hctosys"
else 
   glogger -s "$0 unknown parameter <$1>"
   exit
fi
 
/sbin/hwclock ${hwc_parms} ${cmd}
