#!/bin/bash
source /_config/bin/g2v_funcs.sh

NAME="shoutcast"
COVER_DIR="/audio/covers"
UTIL_DIR="/_config/bin"

COV_PATH="$COVER_DIR/$NAME"
[ ! -d $COV_PATH ] && mkdir -p $COV_PATH
DEF_COVER="$COV_PATH/$NAME.jpg"

OUT_FILE="/tmp/shoutcast.fxd"
TARGET_FILE="/usr/share/freevo/fxd/shoutcast.fxd"

if [ "$1" != "" ] ; then
   depth=$1
else
   depth=10
fi
      
XMLVAR=""
function xmlize () {
   str=${1//&*;/_}
   str=${str//<*>/}
   str=${str//\"/}
   str=${str//\!/}
   while ( strstr "$str" ".." ) ; do
      str=${str//../.}
   done
   while ( strstr "$str" "__" ) ; do
      str=${str//__/_}
   done
   XMLVAR="${str//&/}"
}

COVER=""

function check_cover () {
   COVER="$COV_PATH/${1}-logo"
   [ ! -e "$COVER" -a ! -h "$COVER" ] && ln -s "$NAME.jpg" "$COVER"
}

function write_station () {
   echo "      <audio title=\"${title//&/}\">" >> $OUT_FILE
   check_cover   "${homepage}"
   echo "        <cover-img>$COVER</cover-img>" >> $OUT_FILE
   echo "        <playlist/>" >> $OUT_FILE
   echo "        <reconnect/>" >> $OUT_FILE
   echo "        <url>${URL}${link//&/&amp;}</url>" >> $OUT_FILE
   echo "        <info>" >> $OUT_FILE
   echo "        <users>$users</users>" >> $OUT_FILE
   echo "        <song>$song</song>" >> $OUT_FILE
   echo "        <streaminfo>$type $bitrate</streaminfo>" >> $OUT_FILE
   echo "        <bitrate>$bitrate kB</bitrate>" >> $OUT_FILE
   echo "        <description>Users: $users                    $type $bitrate kB                       ${song}</description>" >> $OUT_FILE
   echo "        </info>" >> $OUT_FILE
   echo "      </audio>" >> $OUT_FILE
   title=""
   link=""
   song=""
   type=""
   qual=""
   bitrate=""
   users=""
   homepage=""
}

echo "Searching shoutcast genres ..."

URL="http://www.shoutcast.com"
GENRES=$(wget -O - "${URL}/directory" 2>/dev/null |grep "<option value=\"" | cut -f 2 -d '"' | sort -u)
[ GENRES = "" ] && GENRES='""'
#GENRES="Electronic\">Electronic"
#GENRES=$(ls /tmp/*.shc |cut -f 3 -d "/" |cut -f 1 -d ".")
echo "<?xml version=\"1.0\" ?>" > $OUT_FILE
echo "<freevo>" >> $OUT_FILE
echo "  <container title=\"Shoutcast Radios\" type=\"webradio\">" >> $OUT_FILE
echo "  <cover-img>$DEF_COVER</cover-img>" >> $OUT_FILE

link=""
for i in $GENRES ; do
   genre=${i/*>/}
   genre=${genre// /}
   genre=${genre//&/n}
   genre=${genre//\//_}
   echo "Searching stations for genre <$genre> ..."
   wget -O - "${URL}/directory/index.phtml?orderby=listeners&sgenre=${i/\"*}&numresult=$depth" 2>/dev/null | grep -A 11 "href=\"/sbin/shoutcast-playlist.pls" | 
             tr -d "\200-\377" | tr -d "\0-\11" | tr -d "\13-\37" > /tmp/$genre.shc
   echo "    <container title=\"${genre}\">" >> $OUT_FILE
   check_cover "$genre"
   echo "    <cover-img>$COVER</cover-img>" >> $OUT_FILE

   cat /tmp/$genre.shc | while read line ; do
      case "${line}" in
         *\<a\ href=\"*)
            if [ "$link" != "" ] ; then
               write_station
            fi
            link=${line#*<a href=\"}     
            link=${link%%\">*}
            ;;
         *_scurl\"\ href=\"*)
            str=${line#*_scurl\" href=\"}            
            homepage=${str%%\"*}
	    homepage=${homepage#*//}
	    homepage=${homepage%%/*}
	    homepage=${homepage%%&*}
	    homepage=${homepage%%\?*}	    
	    homepage=${homepage%%\ *}	    
	    homepage=${homepage%%:*}	    
            str=${str#*\">}
            xmlize "${str%%<\/a>*}"
            title=$XMLVAR            
            ;;
         *Playing:\</font\>*)
            str=${line#*Playing:</font>}
            xmlize "${str%%</font>*}"
            song=$XMLVAR
            ;;
         *all\ Type\ data\ is\ white*)
            type=${line#* color=\"*\">}
            type=${type%%</font>*}
            ;;
         *\"\>*/*\</font\>\</td\>)
            users=${line#* color=\"*\">}
            users=${users%%<*}
            ;;
         *\"\>*\</font\>\</td\>)
            bitrate=${line#*FFFFFF\">}
            bitrate=${bitrate%%</font>*}
            ;;
      esac
   done
   if [ "$link" != "" ] ; then
      write_station
   fi
   echo "    </container>" >> $OUT_FILE
done
echo "  </container>" >> $OUT_FILE
echo "</freevo>" >> $OUT_FILE
cp -f $OUT_FILE $TARGET_FILE
