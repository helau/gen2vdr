#!/bin/bash
source /_config/bin/g2v_funcs.sh

# CONFIG START
MAX_ROWS=24
MAX_COLS=78
#ADM_DIR="."
CONF="$1"
MY_CONF="/tmp/.conf.save"
LXDIALOG="lxdialog"
# CONFIG END

glogger "Starte $0"


# save admin.conf
cp "$CONF" "${MY_CONF}"

LFILLER="------------------------------------------------------------------------------------"
FFILLER="%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

#TERM=linux
eval {line,subl}=0
while read i ; do
   line=$((${line}+1))
   case ${i:0:1} in
      :) subl=$((${subl}+1))
         mainmenu=$mainmenu":{submenu[${subl}]} \"${i/:} --->\" "
         str=${i/:}
         len=${#str}
         if [ $len -lt 70 ] ; then
            lf=$(((70-$len)/2+2))
            rf=$((70-$len-$lf))
            str="${LFILLER:0:$lf}${str}${LFILLER:0:$rf}"
         fi
         submenu[$subl]="${line} \"${str}\" "
      ;;
      -) len=${#i}
         if [ $len -lt 70 ] ; then
            lf=$(((70-$len)/2))
            rf=$((70-$len-$lf))
            str="${LFILLER:0:$lf}${i}${LFILLER:0:$rf}"
         else
            str=$i
         fi
         submenu[$subl]=${submenu[$subl]}"${line} \"${str}\" "
      ;;
      /) IFS=: s=($i)
         case ${s[3]} in
            B) value[$line]=$(echo ${s[5]} | cut -f $((${s[2]}+1)) -d ',')
               ld="<"; rd=">"
            ;;
            L) value[$line]=${s[2]}
               ld="<"; rd=">"
            ;;
            I|A) value[$line]=${s[2]}
               ld="["; rd="]"
            ;;
         esac
         if [ ${#s[6]} -lt 45 ] ; then
            LEN=$((44-${#s[6]}))
            FILLER="${FFILLER:0:$LEN}"
         else
            FILLER=""
         fi
         submenu[$subl]=${submenu[$subl]}"${line} \"${FILLER}${s[6]} ${ld} \${value[$line]} ${rd}\" "
      ;;
   esac
done < ${MY_CONF}

unset IFS

dialog_geometry() {
   ROWS="${1:-24}"
   COLS="${2:-78}"
   ROWS="${ROWS/#0/24}"
   COLS="${COLS/#0/78}"
   if [ "${ROWS}" -lt 24 -o "${COLS}" -lt 78 ] ; then
      echo $"Your display is too small to run this script!"
      echo $"It must be at least 24 lines by 78 columns!"
      echo "`stty size` (stty size) ..."
      exit 1
   else
      ROWS="$((ROWS-2))"
      COLS="$((COLS-2))"
      MSIZE="${ROWS} ${COLS} $((ROWS-6))"
   fi
   MAX_ROWS=$ROWS
   MAX_COLS=$COLS
}
SAVE_CHANGES=0
dialog_geometry `stty size 2>/dev/null`
MAINMENU="${LXDIALOG} --title "G2V-Dialog" --menu '' ${MSIZE} \"\${mainchoice}\" ${mainmenu}"
while : ; do
#   glogger "cmd: $(echo ${MAINMENU})"
   { mainchoice=`eval "${MAINMENU}" 2>&1 >&3 3>&-`; } 3>&1
   rc=$?
#   glogger "RC: $rc <$mainchoice>"
   case "${rc}" in
      0|3|4|5|6)
         x=$(eval echo \$${mainchoice/:} |tr "%" " ")
         if [ -z "${x}" ] ; then
            echo $"submenu currently not available ..."
            sleep 2
            continue
         fi
         SUBMENU="${LXDIALOG} --title 'Submenu' --menu '' ${MSIZE} \"\${subchoice}\" ${x}"
         while : ; do
#            { subchoice=`eval "${SUBMENU//%/ }" 2>&1 >&3 3>&-`; } 3>&1
            { subchoice=`eval "${SUBMENU}" 2>&1 >&3 3>&-`; } 3>&1
            subrc=$?
            #glogger "Sub RC: $subrc <$subchoice>"
            case $subrc in
               0|3|4|5|6)
                  while read i ; do
                     case ${i:0:1} in
                        -) y=
                        ;;
                        /) IFS=: s=($i)
                           unset IFS
                           case ${s[3]} in
                              B|L)
                                 NVAL="${s[2]}"
                                 #glogger "<${s[2]}><${s[3]}><${s[4]}><${s[5]}><${value[$subchoice]}>"
                                 if [ "$subrc" != "0" -o "${s[3]}" = "B" ] ; then
                                    #glogger "echo ${s[5]// /_} | tr , \\n | grep -n \"^${value[$subchoice]// /_}$\""
                                    IFS=: NUM=($(echo "${s[5]// /_}" | tr "," "\n" | grep -n "^${value[$subchoice]// /_}$"))
                                    unset IFS
                                    #glogger "<${s[2]}><${s[3]}><${s[4]}><${s[5]}> NUM:$NUM"
                                    m=$((${NUM[0]}+1))
                                    value[$subchoice]="$(echo ${s[5]} | cut -f $m -d ',')"
                                    #eval value[$subchoice]=$(echo ${s[5]} | cut -f $m -d ',') 2>/dev/null
                                    #glogger "<s2><$NV><${value[$subchoice]}>"
#                                    if [ -z "${value[$subchoice]}" ] ; then
                                    if [ "${value[$subchoice]}" = "" ] ; then
                                       m=1
                                       value[$subchoice]="$(echo ${s[5]} | cut -f 1 -d ',')"
                                       #eval value[$subchoice]=$(echo ${s[5]} | cut -f 1 -d ',') 2>/dev/null
                                    fi
                                    #glogger "<s3><${value[$subchoice]}>"
                                    if [ "${s[3]}" = "B" ] ; then
                                       NVAL=$(($m-1))
                                    else
                                       NVAL=${value[$subchoice]}
                                    fi
                                    if [ "$NVAL" != "${s[2]}" ] ; then
                                       sed -i "${subchoice}s/\(:${s[2]//\//\\/}:\)/:${NVAL}:/" "${MY_CONF}"
                                    fi
                                    y=
                                 else
                                    y=x2
                                 fi
                              ;;
                              I|A) y=x1
                              ;;
                           esac
                        ;;
                     esac
                  done < <(head -n ${subchoice} "${MY_CONF}" | tail -n 1)
                  unset IFS
                  if [ "${y}" = "x1" ] ; then
                     MAXW=$((COLS-1))
                     TXT="Wertebereich: ${s[5]}"
                     if [ ${#TXT} -gt ${#s[6]} ] ; then
                        W=${#TXT}
                     else
                        W=${#s[6]}
                     fi
                     [ $((W+10)) -lt $MAXW ] && MAXW=$((W+10))
                     while : ; do
                        #if { STOUT=$(${LXDIALOG} --clear --title "${s[6]}" --inputbox "Wertebereich: ${s[5]}" 8 $MAXW "${s[2]}" 2>&1 >&3 3>&-); } 3>&1 ; then
                        glogger ${LXDIALOG} --clear --title "${s[1]} - ${s[6]}" --inputbox "${TXT}" 8 $MAXW "${s[2]}"
                        ${LXDIALOG} --clear --title "${s[1]} - ${s[6]}" --inputbox "${TXT}" 8 $MAXW "${s[2]}" 2>/tmp/val
                        rc=$?
                        #glogger "ib rc: $rc"
                        if [ $rc -eq 0 ] ; then
                           STOUT=$(cat /tmp/val)
                           if [ "${s[2]}" != "${STOUT}" ] ; then
                              sed -i "${subchoice}s|:${s[1]}:${s[2]}:|:${s[1]}:${STOUT}:|" "${MY_CONF}"
                              eval value[$subchoice]="${STOUT// /\\ }" 2>/dev/null
                              #glogger "ib nv: >${value[$subchoice]}<"
                           fi
                           break
                        elif [ $rc -eq 1 ] ; then
                           # help
                           continue
                        else
                           break
                        fi
                     done
                  elif [ "${y}" = "x2" ] ; then
                     VARS="${s[5]},"
                     m=1
                     IDX=1
                     PARMS=""
                     while [ "$VARS" != "" ] ; do
                        ACT_VAR=${VARS%%,*}
                        if [ "$ACT_VAR" = "${s[2]}" ] ; then
                           IDX=$m
                        fi
                        PARMS="${PARMS}${m} \"${ACT_VAR}\" "
                        m=$(($m+1))
                        VARS=${VARS#*,}
                     done
                     [ $m -gt $(($MAX_ROWS-5)) ] && m=$(($MAX_ROWS-5))
                     MS="$(($m+5)) 60 $((m-1))"
                     glogger "${LXDIALOG} --title \"${s[1]} - ${s[6]}\" --menu \"\" ${MS} \"\${IDX}\" ${PARMS}"
                     SMENU="${LXDIALOG} --title \"${s[1]} - ${s[6]}\" --menu \"\" ${MS} \"\${IDX}\" ${PARMS}"
                     while : ; do
                        glogger "IDX: $IDX"
                        { schoice=`eval "${SMENU}" 2>&1 >&3 3>&-`; } 3>&1
                        src=$?
                        #glogger "SRC: $src <$schoice>"
                        #${LXDIALOG} --title "${s[6]}" --menu ${MSIZE} "${IDX}" ${PARMS} 2>/tmp/.drc
                        if [ $src -eq 0 -o $src -eq 6 ] ; then
                           IDX=$schoice
                           NVAL=$(echo "${s[5]}" | cut -f $IDX -d ",")
                           break
                        elif [ $src -eq 2 ] ; then
                           # help
                           IDX=${schoice%% *}
                           continue
                        else
                           break
                        fi
                     done
                     if [ "$NVAL" != "${s[2]}" ] ; then
                        sed -i "${subchoice}s/\(:${s[2]//\//\\/}:\)/:${NVAL}:/" "${MY_CONF}"
                        eval value[$subchoice]="${NVAL}" 2>/dev/null
                     fi
                  fi
               ;;
               1) break
               ;;
               2) subchoice=${subchoice%% *}
               ;;
            esac
         done
      ;;
      1) if [ "$(diff -uN "$ADM_CONF" "$MY_CONF")" != "" ] ; then
            ${LXDIALOG} --title "G2V-Dialog" --clear --yesno "Sollen die Einstellungen gesichert werden ?" 5 50
            EXIT_CODE=$?
            [ $EXIT_CODE -eq 0 ] && SAVE_CHANGES=1
            [ $EXIT_CODE -lt 2 ] && break
         else
            break
         fi
      ;;
      2) :
      ;;
   esac
done
if [ $SAVE_CHANGES -ne 1 ] ; then
   glogger -s "Es wurden keine Aenderungen gemacht"
   exit
fi
glogger -s "Sichere ${CONF} als ${CONF}.bak"
cp -af "${CONF}" "${CONF}.bak"
cp "$MY_CONF" "$CONF"
