#!/bin/bash
VDR2JPEG="$(which vdr2jpeg)"
FFMPEG="$(which ffmpeg)"
IMGUSE="VDR2JPEG"

VDRREC="/video"  # you may need to adjust this
TVFILE="../tvshow.nfo"
NFOFILE="001.nfo"

DVDTHUMB="../folder.jpg"
DVDOFFSETVDR="18000"
DVDOFFSETSEC="5000"
DVD_XRES="144"
DVD_YRES="176"

FANTHUMB="../fanart.jpg"
FANOFFSETVDR="20000"
FANOFFSETSEC="6000"
FAN_XRES="1280"
FAN_YRES="720"

CHECKRUNNING=$(/bin/pidof -x $0|wc -w)

if [ $CHECKRUNNING -gt 2 ];then
  echo "$CHECKRUNNING"
  echo "scanvdr already running ..."
  exit 0
fi

if [ "$1" = "-new" ];then
  echo "regenerating all files ..."
  find $VDRREC -name "*.jpg" -exec rm {} \;
  find $VDRREC -name "*.nfo" -exec rm {} \;
elif [ -n "$1" ];then
  echo "  Usage:"
  echo "  $0"
  echo "      - or -"
  echo "  $0 -new"
  exit 0
fi


for i in $(find $VDRREC -name "info*" -type f)
do
  VDRDIR=$(dirname $i)
  VDRINFO=$(basename $i)
  cd $VDRDIR

  if [ -f $VDRINFO ];then
     AIRED=$(basename $VDRDIR | awk -F'.' '{print $1}')
     DAUER=$(grep "^E " $VDRINFO | awk '{print $4/60}' | awk -F'.' '{print $1}')
     TITEL=$(grep "^T " $VDRINFO | sed "s/^T //")
     INHALT=$(grep "^D " $VDRINFO | sed "s/^D //")
     KURZTEXT=$(grep "^S " $VDRINFO | sed "s/^S //")
     if [ -z "$KURZTEXT" ];then
          KURZTEXT="$TITEL"
     fi
  fi

  echo "${TITEL}:"

  echo "creating database infos ..."

  COUNTREC=$(find .. -name "*.rec" | wc -l)
  COUNTRECTS=$(find .. -name "*.ts" | wc -l)
  let COUNTREC=COUNTREC+COUNTRECTS

  HTEXT=$(find .. -name $VDRINFO | sort -n | xargs cat | grep "^S " | sed "s/^S //")

  if [ -z "$HTEXT" ];then
        HTEXT="$DAUER min: $INHALT"
  elif [ "$COUNTREC" = "1" ];then
        HTEXT="[ ${HTEXT} ]
$DAUER min: $INHALT"
  fi

  echo "<tvshow>"                  > $TVFILE
  echo "<title>$TITEL</title>"    >> $TVFILE
  echo "<plot>$HTEXT</plot>"      >> $TVFILE
  echo "</tvshow>"                >> $TVFILE


  if [ ! -f $NFOFILE ];then

     echo "<episodedetails>"                     > $NFOFILE
     echo "<title>$KURZTEXT</title>"            >> $NFOFILE
     echo "<rating></rating>"                   >> $NFOFILE
     echo "<season></season>"                   >> $NFOFILE
     echo "<episode></episode>"                 >> $NFOFILE
     echo "<plot>$DAUER min: $INHALT</plot>"    >> $NFOFILE
     echo "<credits>VDR</credits>"              >> $NFOFILE
     echo "<director></director>"               >> $NFOFILE
     echo "<aired>$AIRED</aired>"               >> $NFOFILE
     echo "<runtime>$DAUER min</runtime>"       >> $NFOFILE
     echo "<actor></actor>"                     >> $NFOFILE
     echo "</episodedetails>"                   >> $NFOFILE

  fi

  if [ "$VDRINFO" = "info.vdr" ];then
       VIDEOFILE="001.vdr"
  else
       VIDEOFILE="00001.ts"
  fi

  if [ -f $VDR2JPEG ] && [ "$IMGUSE" = "VDR2JPEG" ] && [ "$VDRINFO" = "info.vdr" ];then

     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails ..."
       $VDR2JPEG -x $DVD_XRES= -y $DVD_YRES -f $DVDOFFSETVDR -r .
       mv 000${DVDOFFSETVDR}.jpg $DVDTHUMB
     fi

     if [ ! -f $FANTHUMB ];then
       echo "creating FANART thumbnails ..."
       $VDR2JPEG -x $FAN_XRES= -y $FAN_YRES -f $FANOFFSETVDR -r .
       mv 000${FANOFFSETVDR}.jpg $FANTHUMB
     fi

  elif [ -f $FFMPEG ];then

     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails ..."
       $FFMPEG -i $VIDEOFILE -itsoffset $DVDOFFSETSEC -s ${DVD_XRES}x${DVD_YRES} -f image2 -vframes 1 -y temp.jpg
       mv temp.jpg $DVDTHUMB
     fi

     if [ ! -f $FANTHUMB ];then
       echo "creating FANART thumbnails ..."
       $FFMPEG -i $VIDEOFILE -itsoffset $FANOFFSETSEC -s ${FAN_XRES}x${FAN_YRES} -f image2 -vframes 1 -y temp.jpg
       mv temp.jpg $FANTHUMB
     fi

  fi

  echo "---"

done

