#!/bin/bash
source /_config/bin/g2v_funcs.sh

# CONFIG START
CMD_DIR="/etc/vdr"
#CMD_DIR="."
CMD_CONF="${CMD_DIR}/commands.conf"
LXDIALOG="dialog"
# CONFIG END

export TERM=linux
eval {line,subl,subidx}=0
while read i ; do
   line=$((${line}+1))

   if [ "${i: -2}" = " {" ] ; then
      subl=$((${subl}+1))
      subidx=0
      mainmenu=${mainmenu}"${subl} \"${i% \{} --->\" "
      submenu[$subl]="${i% \{}"
   elif [ "${i}" != "" -a "${i:0:1}" != " " ] ; then
      subidx=$((${subidx}+1))
      vidx=$((($subl*100)+$subidx))
      value[$vidx]=${i#* :}
      txt=${i%% :*}
      submenu[$subl]=${submenu[$subl]}"${subidx} \"${txt#- }\" "
   fi
done < <(cat ${CMD_CONF} | tr "\t" " " | tr -s " ")
#done < ${CMD_CONF}

unset IFS

#set -x
mainchoice=1
while : ; do
   MM="${LXDIALOG} --default-item ${mainchoice} --title \"Gen2VDR Befehle\" --menu \"\" 0 0 0 ${mainmenu}"
   eval $MM 2> /tmp/.dlgrc
   rc=$?
   mainchoice=$(cat /tmp/.dlgrc)
   #glogger "RC: $rc <$mainchoice>"
   if [ $rc -eq 1 -o $rc -gt 6 ] ; then
      break
   elif [ $rc -ne 2 ] ; then
      x=${submenu[$mainchoice]}
      if [ -z "${x}" ] ; then
         echo $"submenu currently not available ..."
         sleep 2
         continue
      fi
      subchoice=1

      while : ; do
#            { subchoice=`eval "${SUBMENU//%/ }" 2>&1 >&3 3>&-`; } 3>&1
         SM="${LXDIALOG} --default-item ${subchoice} --title \"${x%%:*}\" --menu \"\" 0 0 0 ${x#*:}"
         eval $SM 2> /tmp/.dlgrc
         subrc=$?
         subchoice=$(cat /tmp/.dlgrc)
         #glogger "Sub RC: $subrc <$subchoice>"
         if [ $subrc -eq 1 -o $subrc -gt 6 ] ; then
            break
         elif [ $subrc -ne 2 ] ; then
            vidx=$((($mainchoice*100)+$subchoice))
            #glogger "CMD: <${value[$vidx]}>"
            NUM_CMDS=0
            WIDTH_CMD=30
            CMD_STRING=""
            CMDS="${value[$vidx]# };"

            while [ "$CMDS" != "" ] ; do
               CMD=${CMDS%%;*}
               [ ${#CMD} -gt $WIDTH_CMD ] && WIDTH_CMD=${#CMD}
               NUM_CMDS=$(($NUM_CMDS+1))
               CMDS="${CMDS#*;}"
               CMD_STRING="${CMD_STRING}\\n${CMD# }"
            done

            ${LXDIALOG} --title "Befehl(e) ausfuehren" --clear --yesno "${CMD_STRING}"  $((NUM_CMDS+6)) $((WIDTH_CMD+9))
            EXIT_CODE=$?
            if [ $EXIT_CODE -eq 0 ] ; then
               clear
               glogger -s "Starte <${value[$vidx]}>"
               eval ${value[$vidx]}
               rc=$?
               echo ""
               echo "------ RC: $rc --- Weiter mit Return ------"
               read
            fi
         else
            :
         fi
      done
   else
      :
   fi
done
