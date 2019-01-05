#!/bin/bash
source /_config/bin/g2v_funcs.sh
glogger -s "$0 $1 $2 $3"
VDR_CONF="/etc/vdr.d/conf/vdr"

DO_EXEC=0
NAME=$1
if [ "$NAME" = "-x" ] ; then
   DO_EXEC=1
   shift
   NAME=$1
elif [ "$NAME" = "" ] || [ "${NAME:0:1}" = "-" ] ; then
   echo "Syntax: $0 [-x] <var_name> <var_value> [<admin_conf> [<vdr_conf>]]"
   exit
fi

[ "$3" != "" ] && [ -f $3 ] && ADMIN_CFG_FILE=$3
[ "$4" != "" ] && [ -f $4 ] && VDR_CONF=$4

VAL=$2

if [ "$NAME" = "PLUGINS" ] ; then
   /etc/vdr/plugins/admin/cfgplg.sh "$VAL"
   exit 0
fi

NLINE=$(grep -m 1 ":$NAME:" $ADMIN_CFG_FILE)

if [ "$NLINE" = "" ] ; then
   glogger -s "AdmVar: <$NAME> not found"
   exit 1
fi

SCRIPT=${NLINE%%:*}
NL=${NLINE#*:$NAME:}

OLDVAL=${NL%%:*}
NL=${NL#*:}
TYPE=${NL%%:*}
NL=${NL#*:}
DEFVAL=${NL%%:*}
NL=${NL#*:}
ALLOWED=${NL%%:*}
NL=${NL#*:}
COMMENT=${NL%%:*}
NEWVAL=""

case "$TYPE" in
   L)
      OV=""
      for IDX in $(seq 1 99) ; do
         VALC=$(echo "$ALLOWED," | cut -f $IDX -d ",")
         if [ "$VALC" = "" ] ; then
            break
         fi
         [ "${VAL}" = "${VALC}" ] && NEWVAL=$VAL
         [ "${OLDVAL}" = "${VALC}" ] && OV=$OLDVAL
         [ $IDX -eq 1 ] && DEFVAL=$VALC
      done
      if [ "$NEWVAL" = "" ] ; then
         glogger -s "Value <$VAL> is not valid for $NAME"
         if [ "$OV" != "" ] ; then
            NEWVAL=$OV
         else
            glogger -s "Old Value <$OLDVAL> is not valid for $NAME"
            NEWVAL=$DEFVAL
         fi
         VAL=$NEWVAL
      fi
      ;;
   A | F)
      LEN=$(echo "$VAL" | wc -c)
      if [ $(($LEN - 1)) -gt $DEFVAL ] ; then
         glogger -s "<$VAL> is too long for $NAME"
         NEWVAL=$OLDVAL
      else
         if [ "$ALLOWED" = "-d" -o "$ALLOWED" = "-f" ] ; then
            if [ $ALLOWED "$VAL" ] ; then
               NEWVAL=$VAL
            else
               glogger -s "<$VAL> does not exist ($NAME)"
               NEWVAL=$OLDVAL
            fi
         elif [ "$ALLOWED" = "-D" -o "$ALLOWED" = "-F" ] ; then 
            if [ "$(echo "$VAL" | grep "^[/]")" != "" ] ; then
               NEWVAL=$VAL
            else
               glogger -s "<$VAL> is not valid for $NAME"
               NEWVAL=$OLDVAL
            fi
         else
            if [ "$(echo "$VAL" | grep -v "^[${ALLOWED}]*\$")" = "" ] ; then
               NEWVAL=$VAL
            else
               glogger -s "<$VAL> is not valid for $NAME"
               NEWVAL=$OLDVAL
            fi
         fi
      fi
      VAL=$NEWVAL
      ;;
   B)
      if [ "$VAL" = "0" ] || [ "$VAL" = "1" ] ; then
         NEWVAL=$VAL
      else
         glogger -s "Value <$VAL> is not valid for $NAME"
         if [ "$OLDVAL" = "0" ] || [ "$OLDVAL" = "1" ] ; then
            NEWVAL=$OLDVAL
         else
            glogger -s "Old value <$VAL> is not valid for $NAME"
            if [ "$DEFVAL" = "0" ] || [ "$DEFVAL" = "1" ] ; then
               NEWVAL=$VAL
            else
               glogger -s "Def value <$VAL> is not valid for $NAME - setting to 0"
               NEWVAL=0
            fi
         fi
      fi
      VAL=$NEWVAL
      ;;
   I)
      MINVAL=${ALLOWED%,*}
      MAXVAL=${ALLOWED#*,}
      if [ "$VAL" != "" -a $VAL -ge $MINVAL -a $VAL -le $MAXVAL ] ; then
         NEWVAL=$(printf "%d" $VAL)
      else
         glogger -s "Value <$VAL> is not valid for $NAME"
         if [ $OLDVAL -ge $MINVAL ] && [ $OLDVAL -le $MAXVAL ] ; then
            NEWVAL=$(printf "%d" $OLDVAL)
         else
            glogger -s "Old Value <$OLDVAL> is not valid for $NAME"
            if [ $DEFVAL -ge $MINVAL ] && [ $DEFVAL -le $MAXVAL ] ; then
               NEWVAL=$(printf "%d" $DEFVAL)
            else
               glogger -s "Def Value <$DEFVAL> is not valid for $NAME - setting to $MINVAL"
               NEWVAL=$(printf "%d" $MINVAL)
            fi
         fi
      fi
      VAL=$NEWVAL
      ;;
   *)
      glogger -s "Illegal line in $ADMIN_CFG_FILE :"
      glogger -s "<$TYPE>$NLINE"
      exit 1
      ;;
esac

if [ "$NEWVAL" = "" -a "$TYPE" != "A" ] ; then
   glogger -s "Value <$VAL> is not valid for $NAME"
   exit 1
fi

if [ "$NEWVAL" != "$OLDVAL" ] ; then
   glogger -s "Changing $NAME to <$NEWVAL> from <$OLDVAL> in $ADMIN_CFG_FILE"
   sed -i $ADMIN_CFG_FILE -e "s|\:$NAME\:$OLDVAL\:|\:$NAME\:$NEWVAL\:|"
fi

if [ "${NAME:0:4}" != "PLG_" ] ; then
   VE=$(grep "^${NAME}=" $VDR_CONF)
   if [ "$VE" = "" ] ; then
      glogger -s "Adding ${NAME}=\"${VAL}\" to $VDR_CONF"
      echo "" >> $VDR_CONF
      echo "# $COMMENT" >> $VDR_CONF
      echo "${NAME}=\"${VAL}\"" >> $VDR_CONF
   else
      OLDVAL=$(echo $VE | cut -f 2 -d '"' )
      if [ "$VAL" != "$OLDVAL" ] ; then
         glogger -s "Changing ${NAME} to <${VAL}> from <$OLDVAL> in $VDR_CONF"
         sed -i $VDR_CONF -e "s|^${NAME}=.*|${NAME}=\"${VAL}\"|"
      fi
   fi
fi

[ "$DO_EXEC" = "1" ] && [ -x "$SCRIPT" ] && [ "$SCRIPT" != "/etc/vdr/plugins/admin/setvdrconf.sh" ] && $SCRIPT
