#!/bin/bash
source /_config/bin/g2v_funcs.sh
APP_DIR="/_config/apps"

DEF_USER="root"
DEF_CMD="/_config/bin/g2v_launcher.sh"

APP="$1"
CMDFILE="$2"

if [ "${APP#*.}" != "$APP" ] ; then
   GROUP="${APP%%.*}"
   APP="${APP#*.}"
else
   GROUP=""
fi

USER=""
CMD=""
APP_STR="$(grep "^${APP}:" ${APP_DIR}/${GROUP}.apps 2>/dev/null)"
if [ "${APP_STR}" != "" ] ; then
   str=${APP_STR#*:}
   USER=${str%%:*}
   CMD=${str#*:}
fi

if [ "$CMD" = "" ] ; then
   /etc/vdr/plugins/admin/cfggui.sh -check
   CMD="$DEF_CMD"
   USER="$DEF_USER"
elif [ "$USER" = "" ] ; then
   USER="$DEF_USER"
fi

echo "#!/bin/bash" > $CMDFILE
echo "export DISPLAY=${DISPLAY=:-:0.0}" >> $CMDFILE
echo "$CMD" >> $CMDFILE
chmod +x $CMDFILE
echo "$USER"
