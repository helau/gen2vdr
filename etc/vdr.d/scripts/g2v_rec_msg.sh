#!/bin/bash
# ---
# g2v_rec_msg.sh
# Skript dient zur Anzeige von "Aufnahme"- und "Beendet"-Meldugen
# ---

# VERSION=170215

source /_config/bin/g2v_funcs.sh
# set -x

[[ "${VIDEO: -1}" != "/" ]] && VIDEO="${VIDEO}/"

# "Aufnahme:" und "Beendet:"-Meldung verschönern
TITLE="${2%/*}" ; TITLE="${TITLE#*$VIDEO}"

# Sofortaufnahmezeichen (@) entfernen
while [[ "${TITLE:0:1}" == "@" ]] ; do
  TITLE="${TITLE:1}"
done

# ~ durch / ersetzen, aber auch den Unterverzeichnistrenner / durch ~
LEN=$((${#TITLE}-1)) ; i=0
while [[ $i -le $LEN ]] ; do
  case "${TITLE:$i:1}" in   # Zeichenweises Suchen und Ersetzen
    "/") TITLE="${TITLE:0:$i}~${TITLE:$i+1}" ;;  # "/" durch "~"
    "~") TITLE="${TITLE:0:$i}/${TITLE:$i+1}" ;;  # "~" durch "/"
    "_") TITLE="${TITLE:0:$i} ${TITLE:$i+1}" ;;  # "_" durch " "
      *) ;;
  esac
  ((i++))
done

# Sonderzeichen übersetzen
OUT=""
while [[ "${TITLE//#/}" != "$TITLE" ]] ; do
  tmp="${TITLE#*#}" ; char="${tmp:0:2}" ; ch="$(echo -e "\x$char")"
  OUT="${OUT}${TITLE%%#*}${ch}" ; TITLE="${tmp:2}"
done

TITLE="${OUT}${TITLE}"
REC_FLAG="${2}/.rec"  # Kennzeichnung für laufende Aufnahme
PID_WAIT=13           # Zeit, die gewartet wird, um PID-Wechsel zu erkennen (Im Log schon mal 11 Sekunden!)
MESG="" ; cnt=0

case "$1" in
  before)
    if [[ -e "$REC_FLAG" ]] ; then
      glogger -s "$TITLE: Recording already running? (PID change?) No Message!"
      touch "$REC_FLAG"
      exit 1  # REC_FLAG existiert - Exit
    else
      until [[ -d "$2" ]] ; do  # Warte auf Verzeichnis
        glogger -s "$TITLE: Waiting for directory..."
        sleep 0.5 ; ((cnt++))
        [[ $cnt -gt 5 ]] && break
      done
      touch "$REC_FLAG" || glogger -s "Couldn't create REC_FLAG: $REC_FLAG"
      MESG="Aufnahme:  $TITLE"
    fi
    ;;
  after)
    if [[ -e "$REC_FLAG" ]] ; then
      sleep "$PID_WAIT"  # Wartezeit für PID-Wechsel
      ACT_DATE="$(date +%s)" ; FDATE="$(stat -c %Y "$REC_FLAG")"
      DIFF=$((ACT_DATE - FDATE))
      if [[ $DIFF -le $PID_WAIT ]] ; then  # Letzter Start vor x Sekunden!
        glogger -s "$TITLE: Last start ${DIFF} seconds ago! (PID change?)"
        exit 1  # Exit
      else
        glogger -s "$TITLE: Normal end of recording. Removing REC_FLAG!"
        rm -f "$REC_FLAG"
      fi
    else
      glogger -s "REC_FLAG not found: $REC_FLAG"
    fi
    MESG="Beendet:  $TITLE"
    ;;
  *)
    ;;  # glogger -s "ERROR: unknown state: $1"
esac

if [[ -n "$MESG" ]] ; then  # Meldung ausgeben
  sleep 0.25       # Test VDSB
  glogger -s "$MESG"
  svdrps MESG "$MESG"
fi
