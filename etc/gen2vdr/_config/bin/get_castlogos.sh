#!/bin/bash
COVER_DIR="/audio/covers"
UTIL_DIR="/_config/bin"

if [ "$1" = "check" ] ; then
   old_wg=""
   while [ $(pidof -x $0 | wc -w) -gt 1 ] ; do
       sleep 20
       wget_pids="$(pidof wget)"
       if [ "$wget_pids" == "$old_wg" ] && [ "$wget_pids" != "" ] ; then
          kill -9 $wget_pids
       fi
       old_wg=$wget_pids
   done
else
   screen -dm sh -c "$0 check"
   [ ! -f $COVER_DIR/shoutcast/shoutcast.jpg ] && wget -O $COVER_DIR/shoutcast/shoutcast.jpg http://flinchbot.files.wordpress.com/2007/07/shoutcast.jpg 
   [ ! -f $COVER_DIR/icecast/icecast.jpg ]     && wget -O $COVER_DIR/icecast/icecast.jpg http://fosshelp.org/icecast/logo.jpeg
   for i in $COVER_DIR/shoutcast/*.*.*-logo ; do 
      if [ "$(readlink $i)" == "shoutcast.jpg" ] ; then
         LOGO=$(perl $UTIL_DIR/get_logo.pl "$i" | grep "^Found:" | cut -f 2 -d " ")
         if [ "$LOGO" != "" ] && [ -s "$LOGO" ] ; then
            rm "$i"
            ln -s "$LOGO" "$i"
         fi 
      fi
   done
   for i in $COVER_DIR/icecast/*.*.*-logo ; do 
      if [ "$(readlink $i)" == "icecast.jpg" ] ; then
         LOGO=$(perl $UTIL_DIR/get_logo.pl "$i" | grep "^Found:" | cut -f 2 -d " ")
         if [ "$LOGO" != "" ] && [ -s "$LOGO" ] ; then
            rm "$i"
            ln -s "$LOGO" "$i"
         fi 
      fi
   done
fi   
