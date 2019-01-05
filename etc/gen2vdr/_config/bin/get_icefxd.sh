#!/bin/bash
source /_config/bin/g2v_funcs.sh
NAME="icecast"

COVER_DIR="/audio/covers"
UTIL_DIR="/_config/bin"

COV_PATH="$COVER_DIR/$NAME"
[ ! -d $COV_PATH ] && mkdir -p $COV_PATH
DEF_COVER="$COV_PATH/$NAME.jpg"

OUT_FILE="/tmp/$NAME.fxd"
TARGET_FILE="/usr/share/freevo/fxd/$NAME.fxd"

if [ "$1" != "" ] ; then
   depth=$1
else
   depth=10
fi   

XMLVAR=""
function xmlize () {
   str=${1//&*;/_}
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
   echo "        <users></users>" >> $OUT_FILE
   echo "        <song>$song</song>" >> $OUT_FILE
   echo "        <streaminfo>$type $qual</streaminfo>" >> $OUT_FILE
   echo "        <bitrate>$qual</bitrate>" >> $OUT_FILE
   echo "        <description>${type/ */}_$qual                    ${song}                     ${desc}</description>" >> $OUT_FILE
   echo "        </info>" >> $OUT_FILE
   echo "      </audio>" >> $OUT_FILE
   title=""
   link=""
   song=""
   type=""
   qual=""
   desc=""
   homepage=""
}

echo "Searching $NAME genres ..."

URL="http://dir.xiph.org"
GENRES=$(wget -O - "${URL}/index.php?num=1" 2>/dev/null |grep "</span><a href=\"/by_genre/" |sed -e "s%.*\"/by_genre/%%" |cut -f 1 -d '"'|sort -u)
[ GENRES = "" ] && GENRES='""'

echo "<?xml version=\"1.0\" ?>" > $OUT_FILE
echo "<freevo>" >> $OUT_FILE
echo "  <container title=\"Icecast Radios\" type=\"webradio\">" >> $OUT_FILE
echo "  <cover-img>$DEF_COVER</cover-img>" >> $OUT_FILE

title=""
#set -x

for i in $GENRES ; do 
   wget -O - "${URL}/by_genre/$i" 2>/dev/null | tr -d "\200-\377" | tr -d "[]|" | tr -d "\0-\11" | tr -d "\13-\37" | grep -v "une in" > /tmp/$i.ice
   echo "    <container title=\"$i\">" >> $OUT_FILE
   check_cover "$i"
   echo "    <cover-img>$COVER</cover-img>" >> $OUT_FILE
   echo "Searching stations for genre <$i> ..."
   cat /tmp/$i.ice | while read line ; do 
#      echo "${line}" 
      case "${line}" in
         \<p\>\ \<a\ href*)
            link=${line#*> <a href=\"}
            link=${link%%\"*}
#            echo "Link: <$link>"
	    ;;
         *\<span\ class=\"name\"\>*)
            if [ "$title" != "" ] ; then
               write_station     
            fi   
            case "${line}" in
               *a\ href=\"*)
	          line=${line#* href=\"}
		  homepage=${line%%\"*}
                  homepage=${homepage#*//}
                  homepage=${homepage%%/*}
                  homepage=${homepage%%&*}
                  homepage=${homepage%%\?*}
                  homepage=${homepage%%\ *}
                  homepage=${homepage%%:*}
	          ;;
	       *)
	          ;;	  
	    esac   
            title=${line#*>}
            xmlize "${title%%<*}"
            title=$XMLVAR
            echo "Title: <$title>"
            ;;
         *\<p\ class=\"format\"*)
            case "${line}" in
               *\ title=\"*)
                  qual=${line#* title=\"}
                  qual=${qual%%\"*}
                  qual=${qual/Quality/}
                  qual=${qual/kbps/kB}
                  qual=${qual// /}	          
	          ;;
	       *)
	          ;;	  
	    esac
	    read type
#            echo "Link: <$link>"
#            echo "Type: <$type>"
            ;;
         *class=\"stream-description*)
            desc=${line#*stream-description\">}
            xmlize "${desc%%<*}"
            desc=$XMLVAR
	    ;;
         *class=\"stream-onair*)
            song=${line#*</strong>}
            xmlize "${song%%<*}"
            song=$XMLVAR
#            echo "Desc: <$desc>"
#            echo "Song: <$song>"
            ;;
	  *)
#	    echo "Unknown: <$line>"    
	    ;;
      esac
   done
   if [ "$title" != "" ] ; then
      write_station     
   fi   
   echo "     </container>" >> $OUT_FILE
done
echo "  </container>" >> $OUT_FILE
echo "</freevo>" >> $OUT_FILE
cp -f $OUT_FILE $TARGET_FILE
