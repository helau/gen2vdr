##!/bin/bash
source /_config/bin/g2v_funcs.sh
LABEL_BACK="--cancel-label \"Zurück\""
LABEL_OK="--ok-label \"Starten\""
LABEL_EMPTY="--ok-label \"Zurück\""

APP_DIR="/_config/apps"
GROUP="$1"
TITLE="Gen2VDR Anwendungen"

LABEL2="--no-cancel"
TMP_APP="/tmp/.g2vl"
TMP_RC="/tmp/.g2vlrc"

while [ 1 ] ; do
   glogger "$0 <$GROUP>"
   if [ "$GROUP" != "" ] ; then
      TITLE="$TITLE - $GROUP"
      LABEL2="--cancel-label \"Zurück\""
   else
      TITLE="${TITLE%% - *}"
      LABEL2="--no-cancel"
   fi
   cd ${APP_DIR}

   rm -f $TMP_APP $TMP_RC 2> /dev/null

   cat ${GROUP}.apps | while read i ; do
      APP=${i%%:*}
      if [ "$APP" != "" ] ; then
         if [ ! -e $TMP_APP ] ; then
            echo "Xdialog $LABEL_OK $LABEL2 --menubox \"$TITLE\" 20 40 5 \\" > $TMP_APP
         fi
         echo "\"          ${APP}\" \"\" \\" >> $TMP_APP
      fi
   done

   if [ "$GROUP" = "" ] ; then
      for i in *.apps ; do
         if [ -s $i -a "$i" != ".apps" ] ; then
            if [ ! -e $TMP_APP ] ; then
               echo "Xdialog $LABEL_OK $LABEL2 --menubox \"$TITLE\" 20 40 5 \\" > $TMP_APP
            fi
            echo "\"          ${i%.apps} --->\" \"\" \\" >> $TMP_APP
         fi
      done
   fi
   if [ -e $TMP_APP ] ; then
      echo " 2>$TMP_RC" >> $TMP_APP

      echo "rc=\$?" >>$TMP_APP
      echo "if [ \"\$rc\" = \"1\" ] ; then" >>$TMP_APP
      echo "   echo \"Launcher\" > $TMP_RC" >>$TMP_APP
      echo "elif [ \"\$rc\" != \"0\" ] ; then" >>$TMP_APP
      echo "   rm -f $TMP_RC" >>$TMP_APP
      echo "fi" >>$TMP_APP
   else
      echo "Xdialog --msgbox \"Keine Anwendung in <${APP_DIR}${SUB_DIR}>\" 20 40" > $TMP_APP
      SUB_DIR=""
      echo -n "Launcher" > $TMP_RC
   fi

   bash $TMP_APP
   CHOICE="$(cat $TMP_RC 2>/dev/null|sed -e "s/^[ ]*//")"
   if [ "${CHOICE: -1}" = ">" ] ; then
      GROUP="${CHOICE% *}"
   elif [ "${CHOICE}" = "Launcher" -o "${CHOICE}" = "" ] ; then
      GROUP=""
   else
      /_config/bin/g2v_startapp.sh "${GROUP}.${CHOICE}"
   fi
done
