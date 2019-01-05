#!/bin/bash
# ---
# g2v_record.sh
# Wird vom VDR aufgerufen bei Start und Ende von Aufnahmen, so wie bei Schnitt
# oder wenn eine Aufnahme gelöscht wird
# ---

# VERSION=170214

source /_config/bin/g2v_funcs.sh
# set -x
NOAD='/_config/bin/g2v_noad.sh'
[[ "${VIDEO: -1}" != "/" ]] && VIDEO="${VIDEO}/"

glogger -s "$(date +"%F %R") $0 $1 $2" >> "${VIDEO}/vdr.record" 2>&1
MESG="" ; DO_NOAD=0

case "$1" in
  before)
    DO_NOAD=1
    screen -dm sh -c "/etc/vdr.d/scripts/g2v_rec_msg.sh $1 \"$2\""
    if [[ "$SHAREMARKS" == "1" ]] ; then
      screen -dm sh -c "marks2pts $1 \"$2\""
    fi
  ;;
  after)
    DO_NOAD=1
    screen -dm sh -c "/etc/vdr.d/scripts/g2v_rec_msg.sh $1 \"$2\""
    INFO="$2/info"
    [[ ! -e "$INFO" ]] && INFO="$2/info.vdr"
    EVENTID="$(grep "^E " "$INFO" | cut -f 2 -d " ")"
    if [[ -n "$EVENTID" ]] ; then
      [[ -e "${EPG_IMAGES}/${EVENTID}.jpg" ]] && cp "${EPG_IMAGES}/${EVENTID}"*.jpg "$2" && ln -s "${EVENTID}.jpg" "$2/Cover-Enigma.jpg"
      [[ -e "${EPG_IMAGES}/${EVENTID}.png" ]] && cp "${EPG_IMAGES}/${EVENTID}"*.png "$2" && ln -s "${EVENTID}.png" "$2/Cover-Enigma.png"
    fi
    VDR_CUTTING_DIR="${VIDEO}_CUT_/"
    if [[ "$USE_CUTTING_DIR" == "1" && -d "$VDR_CUTTING_DIR" ]] ; then
      DS="$(du -s "${2}" | cut -f 1)"
      DF="$(df -k "$VDR_CUTTING_DIR" | tail -n 1 |tr -s " " |cut -f 4 -d " ")"
      if [[ $DF -gt $DS ]] ; then
        rd="${2%/[0-9]*}" ; rdb="${rd%/*}/" ; rdn="${rd##*/}" ; rdb="${rdb#$VIDEO}"
        mkdir -p "${VDR_CUTTING_DIR}${rdb}%${rdn}"
        ln -s "${VDR_CUTTING_DIR}${rdb}%${rdn}" "${VIDEO}${rdb}"
        glogger -s "Setze Schnittverzeichnis <${VDR_CUTTING_DIR}${rdb}%${rdn}>"
      else
        glogger -s "Nicht genug Platz auf $VDR_CUTTING_DIR"
      fi
    fi
  ;;
  cut)
    if [[ "$SHAREMARKS" == "1" ]] ; then
      screen -dm sh -c "marks2pts -upload $1 \"$2\""
    fi
  ;;
  edited)
    if [[ "$SHAREMARKS" == "1" ]] ; then
      screen -dm sh -c "marks2pts -upload $1 \"$2\""
    fi
    if [[ -n "$3" ]] ; then         # VDR > 1.7.31
       [[ -e "${3}/Cover-Enigma.jpg" ]] && cp -a "${3}"/*.jpg "$2"
       [[ -e "${3}/Cover-Enigma.png" ]] && cp -a "${3}"/*.png "$2"
    else
       ODIR="${2//\/%//}"  # /% durch / ersetzen
       [[ -e "${ODIR}/Cover-Enigma.jpg" ]] && cp -a "${ODIR}"/*.jpg "$2"
       [[ -e "${ODIR}/Cover-Enigma.png" ]] && cp -a "${ODIR}"/*.png "$2"
    fi
    [[ -z "${PLUGINS/* rectags */}" ]] && sendvdrkey.sh RED
  ;;
  delete)
    # Delete recording
  ;;
  deleted)
    if [[ -L "$2" ]] ; then  # Testen ob es ein Symlink ist
      LNK="$(readlink "$2")"             # Ziel des Links merken
      if [[ -d "$LNK" ]] ; then          # Ist ein Verzeichnis
        mv "$LNK" "${LNK%.rec}.del"      # Umbenennen -> *.del
        ln -s --force -n "${LNK%.rec}.del" "$2"  # Symlink ersetzen
        glogger "Linkziel von $2 wurde angepasst (-> ${LNK%.rec}.del)"
      fi # -d
    fi # -L
 ;;
  started)
    # few seconds after recording has started
  ;;
  *)
    glogger -s "ERROR: unknown state: $1"
  ;;
esac

if [[ -x "$NOAD" && "$DO_NOAD" == "1" && "$SET_MARKS" != "Nie" ]] ; then
  if [[ -z "${PLUGINS/* markad */}" ]] ; then
    glogger -s 'Markad activated - noad ignored'
  else
    screen -dm sh -c "$NOAD $1 \"$2\""
  fi
else
  screen -dm sh -c '/_config/bin/g2v_maintain_recordings.sh'
fi

if [[ -n "$MESG" ]] ; then
  glogger -s "$MESG"
  screen -dm sh -c "svdrpsend.sh MESG $MESG"
fi

screen -dm sh -c "sleep 10; touch ${VIDEO}.update"

exit

