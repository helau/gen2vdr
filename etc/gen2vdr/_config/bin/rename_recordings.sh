#!/bin/bash
source /_config/bin/g2v_funcs.sh

cd /video
for i in */*.rec ; do 
   echo $i 
   SN=${i%%/*}
   RN=${i##*/}
   if [ "$(grep "^${SN//_/ }" /etc/vdr/channels.conf)" != "" ] ; then
      TITLE="$(grep "^T " "$i/info" |cut -b 3- | tr " " "_" |tr "/" "-")"
      if [ -d "${TITLE}/${RN}" ] ; then
         glogger -s "$TITLE existiert bereits"
      else
         [ ! -d "$TITLE" ] && mkdir "$TITLE"
         glogger -s "$TITLE wuerde angelegt"
         mv "$i" "${TITLE}/${RN}"
      fi
   fi
done
touch /video/.update
