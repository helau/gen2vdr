#!/bin/bash
source /_config/bin/g2v_funcs.sh

# check if already running
if [ "$(pidof -x "$0" -o $$ -o $PPID -o %PPID)" != "" ] ; then
   glogger "ERROR: $0 laeuft bereits"
   exit
fi


SRC_DIR="${1%/}"

if [ ! -s "${SRC_DIR}/index" ] ; then
   glogger "ERROR: <${SRC_DIR}/index> nicht vorhanden"
   exit
fi
if [ ! -d "${VIDEO}/rec_marked" ] ; then
   glogger "ERROR: <${VIDEO}/rec_marked> nicht vorhanden"
   exit
fi

# determine if is recording
newest_file="$(ls -t "${SRC_DIR}/" | head -n 1)"
fdate="$(stat -c %Y "${SRC_DIR}/${newest_file}")"
act_date="$(date +%s)"

if [ $(($act_date - 10)) -le $fdate ] ; then
   glogger "ERROR: <$SRC_DIR> wird derzeit benutzt"
   exit
fi

TARGET_DIR="$(readlink "${VIDEO}/rec_marked")"
TARGET_DIR="${TARGET_DIR%/}"

if [ "${TARGET_DIR}" = "${SRC_DIR}" ] ; then
   glogger "ERROR: Ursprung und Ziel sind identisch"
   exit
fi

# Link for undo
UNDO_DIR="${VIDEO}/rec_undo"
rm -f "$UNDO_DIR" > /dev/null 2>&1

# determine old length
cd "${TARGET_DIR}"
idx_size="$(stat -c %s "index")"
rec_len=$(($idx_size*100/8/25))
last_vdrfile=$(ls [0-9][0-9][0-9][0-9][0-9].ts | sort | tail -n 1)
last_idx=${last_vdrfile%.ts}
last_idx=${last_idx#0}
idx=$((${last_idx#0} + 1))

# move files
cd "$SRC_DIR"
for i in 0*.ts ; do
   tgt="$(printf "${TARGET_DIR}/%05d.ts" $idx)"
   mv $i "$tgt"
   ln -s "$tgt" "${i}.undo"
   idx=$(($idx + 1))
done

# save marks, index and info
for i in marks index info.merged ; do
   if [ -e "${TARGET_DIR}/${i}" ] ; then
      cp -fp "${TARGET_DIR}/${i}" "${SRC_DIR}/${i}.undo"
   else
      [ -e "${SRC_DIR}/${i}.undo" ] && rm -f "${SRC_DIR}/${i}.undo"
   fi
done

# add marks
# first 2 Marks for start ( or only 1 if there is a mark not closed
mk=$(printf "%d:%02d:%02d.%02d" $(($rec_len / 60 / 60 / 100)) $((($rec_len % 360000) / 60 / 100)) $((($rec_len % 6000) / 100)) $(($rec_len % 100)))

num_marks=$(cat "${TARGET_DIR}/marks" 2>/dev/null | wc -l)
if [ $(($num_marks % 2)) -eq 0 ] ; then
   echo "$mk" >> "${TARGET_DIR}/marks"
fi
echo "$mk" >> "${TARGET_DIR}/marks"

if [ -s marks ] ; then
   for mark in $(cat marks | cut -f 1 -d " ") ; do
      th=$((${mark%%:*} * 60 * 60 * 100))
      mark=${mark#*:}
      mm=${mark%%:*}
      tm=$((${mm#0} * 60 * 100))
      mark=${mark#*:}
      ms=${mark%%.*}
      ts=$((${ms#0} * 100))
      mhs="${mark:3:2}"
      if [ "$mhs" != "" ] ; then
         ths=${mhs#0}
      else
         ths=0
      fi
      act_pos=$(($rec_len + $th + $tm + $ts + $ths))
      mk=$(printf "%d:%02d:%02d.%02d" $(($act_pos / 60 / 60 / 100)) $((($act_pos % 360000) / 60 / 100)) $((($act_pos % 6000) / 100)) $(($act_pos % 100)))
      echo "$mk" >> "${TARGET_DIR}/marks"
   done
fi

rm "${TARGET_DIR}/index"
screen -dm sh -c "vdr --genindex=\"$TARGET_DIR\"; touch /video/.update"

sleep 3

echo "# Merged from <$SRC_DIR>" >> "${TARGET_DIR}/info.merged"
echo "" >> "${TARGET_DIR}/info.merged"
if [ -s info ] ; then
   cat info >> "${TARGET_DIR}/info.merged"
fi
echo "" >> "${TARGET_DIR}/info.merged"
echo "" >> "${TARGET_DIR}/info.merged"

# check files for determining undo possibility later
cd "${TARGET_DIR}"
du -hsb 0*.ts > "${SRC_DIR}/undo.info"
ln -s "${TARGET_DIR}/" "${SRC_DIR}/undo.link"

# create undo Link
SRC_DEL="${SRC_DIR%.rec}.del"

mv -f "$SRC_DIR" "$SRC_DEL"
ln -s "$SRC_DEL" "$UNDO_DIR"

touch /video/.update

glogger "<$SRC_DIR> wurde an <${TARGET_DIR}> angehaengt"
