#!/bin/bash
SKIN_DIR=/etc/vdr/plugins/skindesigner/
TMPFILE=/tmp/skin_update

rm -f $TMPFILE

#set -x
for i in $(find ${SKIN_DIR} -name ".git" -type d) ; do
   [ ! -d $i ] && continue
   cd ${i%.git}
   echo $i
#   rm po/*.po
#   rm plugin/po/*.po
   original_head=$(git rev-parse HEAD)
   git reset --hard HEAD >/dev/null 2>&1
   git clean -f -d >/dev/null 2>&1
   git pull
   updated_head=$(git rev-parse HEAD) 
   [ $original_head != $updated_head ] && echo -e "  $i --> $(git log --oneline |head -n1)" >> $TMPFILE
done
set +x
[ -s $TMPFILE ] && echo -e "Folgendende Skins wurden aktualisiert:\n$(cat $TMPFILE)"
