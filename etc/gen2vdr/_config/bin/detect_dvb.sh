#!/bin/bash
source /_config/bin/g2v_funcs.sh

if [ "$(pidof vdr)" != "" ] ; then
   /etc/init.d/vdr stop
   RESTART=1
else
   RESTART=0
fi

DVB_CARDS=$(ls -l /dev/dvb/ad*/frontend* 2>/dev/null | wc -l)
PRIM_DVB=$(ls -l /dev/dvb/*/osd* 2>/dev/null | wc -l)
PRIM_DVB_HD=$(lsmod | grep saa716x_ff |wc -l)

$SETVAL "PLG_dvbsddevice" "0"
$SETVAL "PLG_dvbhddevice" "0"
$SETVAL "PLG_xine" "0"
$SETVAL "PLG_xineliboutput" "0"
ALSA=0

if [ "$PRIM_DVB_HD" != "0" ] ; then
   logger -s "Primary DVB HD card found"
   $SETVAL "PLG_dvbhddevice" "99"
   $SETVAL "PLG_remote" "98"
   $SETVAL "VO_DRIVER" "ffdvb"
elif [ "$PRIM_DVB" != "0" ] ; then
   logger -s "Primary DVB SD card found - reducing OSD size"
   sed -i /etc/vdr/setup.conf -e "s/OSDWidthP.*/OSDWidthP = 0.800000/" -e "s/OSDHeightP.*/OSDHeightP = 0.800000/" \
                              -e "s/OSDWidth .*/OSDWidth = 632/" -e "s/OSDHeight .*/OSDHeight = 507/" \
                              -e "s/OSDAspect .*/OSDAspect = 1.066667/" \
                              -e "s/OSDTopP.*/OSDTopP = 0.100000/" -e "s/OSDLeftP.*/OSDLeftP = 0.100000/"
   $SETVAL "PLG_dvbsddevice" "99"
   $SETVAL "VO_DRIVER" "ffdvb"
fi
if [ "$(lsmod |grep "ddbridge")" != "" ] && [ "$(ls /dev/dvb/adapter*/ca* 2>/dev/null)" != "" ] ; then
   /_config/bin/module-update.sh args ddbridge adapter_alloc=0
   $SETVAL "PLG_ddci2" "9"
fi

if [ "$(lsmod |grep "ngene")" != "" ] ; then
   /_config/bin/module-update.sh args ngene shutdown_workaround=1
fi

#ONET_IP="$(bash /_config/bin/detect_onet.sh 2>&1 | grep -i Found)"
#if [ "$ONET_IP" != "" ] ; then
#   logger -s "Found Octonet: ${ONET_IP##* }"
#   $SETVAL "PLG_satip" "9"
#fi

IVTV=$(lsmod| grep "^ivtv")
if [ "$IVTV" = "" ] ; then
   $SETVAL "PLG_pvrinput" "0"
else
   $SETVAL "PLG_pvrinput" "3"
fi
$SETVAL "DVB_CARD_NUM" $DVB_CARDS
if [ "$RESTART" = "1" ] ; then
   /etc/init.d/vdr start
fi
