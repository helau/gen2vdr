#!/bin/bash
# Activy set Display text
source /_config/bin/g2v_funcs.sh

[ "${PLUGINS/* alcd */}" != "" ] && exit
WAKEUP_STR=$(cat $WAKEUP_FILE)
WT=""
LCD_BR=$(grep "alcd.LCDBrightnessOnExit" /etc/vdr/setup.conf | cut -f 2 -d "=")
[ "$LCD_BR" = "" ] && LCD_BR=1
if [ "$WAKEUP_STR" != "" -a $LCD_BR -gt 0 ] ; then
   BREAK_MODE="1"
   NT=${WAKEUP_STR%%;*}
   WT="$(date -d "1970-01-01 UTC $NT seconds" '+%d.%m.%y-%R')"
   WAKEUP_STR=${WAKEUP_STR#*;}
   CH=${WAKEUP_STR%%;*}
   PR=${WAKEUP_STR##*;}
   TEXT="$WT - ${CH// /}|$PR"
else
   LCD_BR="0"
   BREAK_MODE="0"
   TEXT=""
fi
#set -x
afp-tool --powerled-blink=0 --basic-led=0 --message-led=0 --powerbutton=1 --brightness=${LCD_BR// /} --stay=$BREAK_MODE --align=0 --text="${TEXT//\"/\'}"
