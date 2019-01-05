#!/bin/bash
source /_config/bin/g2v_funcs.sh
# Set this if you are using a remote server or another protocol
export LANG=de_DE

export __GL_SYNC_TO_VBLANK=1
export __GL_SYNC_DISPLAY_DEVICE="DFP-1"

if [ "$1" != "-w" ] ; then
#   xinfo=$(xrandr -d :0 -q |grep current)
#   WIDTH=${xinfo#*current }
#   WIDTH=${WIDTH%% *}
#   HEIGHT=${xinfo#*current }
#   HEIGHT=${HEIGHT%%,*}
#   HEIGHT=${HEIGHT##* }
#   GEOMETRY="--geometry ${WIDTH}x${HEIGHT}"
   GEOMETRY="--fullscreen"
else
   GEOMETRY=""
fi

chmod 777 /tmp/corefiles
echo "/tmp/corefiles/core" > /proc/sys/kernel/core_pattern
echo "1" > /proc/sys/kernel/core_uses_pid
ulimit -c unlimited

# Only used if set to manuell
AO="alsa"
#AO="none"
VO="xshm"
XINE_CROP="--post autocrop:enable_autodetect=0,enable_subs_detect=1,soft_start=0,stabilize=1"
#set -x
glogger "$0 starting ..."
LOG_FILE="/log/vdr-xine.log"
/_config/bin/set_refresh.sh
mv -f $LOG_FILE ${LOG_FILE}.org 2>/dev/null

while [ "$(pidof -x /_config/bin/x2vdr.sh)" != "" -a "$(pidof X)" != "" ]; do
   [ "$AO_DRIVER" != "manuell" ] && AO="$AO_DRIVER"

   PARMS="$GEOMETRY"
   if [ "$VO_DRIVER" = "x11" ] ; then
      VO="xshm"
   elif [ "$VO_DRIVER" = "vdpau" ] ; then
      VO="$VO_DRIVER"
   elif [ "$VO_DRIVER" = "vaapi" ] ; then
      VO="$VO_DRIVER"
      PARMS="$PARMS --post tvtime:method=use_vo_driver"
   elif [ "$VO_DRIVER" != "manuell" ] ; then
      VO="$VO_DRIVER"
   fi
   killall -9 vdr-sxfe oxine xine > /dev/null 2>&1

   [ "$VO_CROP" = "1" ] && PARMS="$PARMS $XINE_CROP"
   if [ "${PLUGINS/* xineliboutput */}" = "" ] ; then
   # vdr-sxfe --fullscreen --post tvtime:method=use_vo_driver --config=/root/.xine/config_xineliboutput --verbose --syslog --buffers=1000 --video=vdpau --audio=alsa --reconnect --aspect=16:9 xvdr://127.0.0.1
      CMD_EXE="vdr-sxfe"
      CMD_INPUT="xvdr://127.0.0.1"
      if [ "$VO_ASPECT" = "anamorphic" ] ; then
         ASPECT="16:9"
      elif [ "$VO_ASPECT" = "4_3" ] ; then
         ASPECT="4:3"
      elif [ "$VO_ASPECT" = "dvb" ] ; then
         ASPECT="default"
      else
         ASPECT="auto"
      fi
#      PARMS="$PARMS --config=/root/.xine/config_xineliboutput --video=$VO --audio=$AO --reconnect --aspect=$ASPECT --opengl --hud=opengl"
      PARMS="$PARMS --config=/root/.xine/config_xineliboutput --video=$VO --audio=$AO --reconnect --aspect=$ASPECT"
      if [ "$(pidof xcompmgr)" != "" ] ; then
         PARMS="$PARMS -D"
      fi
      XINECFG="/root/.xine/config_xineliboutput"
   else
      CMD_EXE="xine"
      CMD_INPUT="vdr:/tmp/vdr-xine/stream#demux:mpeg_pes"
      if [ "$VO_ASPECT" = "4_3" ] ; then
         ASPECT="4:3"
      else
         ASPECT=$VO_ASPECT
      fi
#      PARMS="$PARMS --keymap=file:/root/.xine/keymap $XINE_CROP --post vdr --post vdr_video --post vdr_audio --hide-gui --no-lirc --no-splash --no-gui --verbose=2 -V $VO -A $AO -r $ASPECT"
      PARMS="$PARMS --keymap=file:/root/.xine/keymap --post vdr --post vdr_video --post vdr_audio --no-splash --no-logo --hide-gui --no-lirc --no-splash --verbose=$LOG_LEVEL -V $VO -A $AO -r $ASPECT"
      XINECFG="/root/.xine/config"

      for i in ${XINECFG} /root/.xine/keymap ; do
         OS="$(cat ${i}.org | wc -l)"
         NS="$(cat ${i} | wc -l)"
         if [ $NS -lt $OS  ] ; then
            cp ${i}.org ${i}
         else
            cp ${i} ${i}.org
         fi
      done
   fi
   sed -i $XINECFG \
       -e "s/.*\(video.output.vdpau_sd_deinterlace_method\).*/\1:${VO_SD_DEINTERLACE}/" \
       -e "s/.*\(video.output.vdpau_hd_deinterlace_method\).*/\1:${VO_HD_DEINTERLACE}/"

   while [ "$(pidof vdr)" = "" -a "$(pidof -x /_config/bin/x2vdr.sh)" != "" ]; do
      sleep 1
   done

   if [ "$(pidof vdr)" != "" -a "$(pidof X)" != ""  ] ; then
      glogger -s "$0 - starte <$CMD_EXE $PARMS $CMD_INPUT>"
      echo "VDR" > /tmp/.nextappl
#      screen -dm sh -c "sleep 8; svdrpsend.sh HITK ok; sleep 1; svdrpsend.sh HITK ok"
      $CMD_EXE $PARMS "$CMD_INPUT" 2>&1 |tee -a $LOG_FILE
      rc=${PIPESTATUS[0]}
      tail -n 5 $LOG_FILE |logger -s
      echo "" >> $LOG_FILE
      if [ "$rc" = "0" ] ; then
         glogger "xine gui ended"
         screen -dm sh -c "/_config/bin/gg_switch.sh"
         break
      else
         glogger "xine gui died ($rc)"
      fi
      cp $LOG_FILE $LOG_FILE.old
   fi
   sleep 1
done
glogger "$0 - exiting"
