#!/bin/bash
# ---
# linkvid.sh
# Skript zum verlinken von Aufnahmen auf externen Median (USB)
# ---

# VERSION=170215

source /_config/bin/g2v_funcs.sh
# set -x

if pidof -x "$0" -o $$ -o $PPID -o %PPID &>/dev/null ; then
   glogger -s "$0 is already running"
   exit
fi

if [[ -z "$1" || "$1" == "/" ]] || [[ ! -d "$1" && "$1" != "-del" && "$2" != "-del" && "$1" != "-check" ]] ; then
   echo
   echo "Syntax: $0 <source> [-del]"
   echo '   source: Verzeichnis mit VDR-Aufnahmen'
   echo
   echo "z.B. $0 /media"
   echo '   sucht nacht allen Aufnahmen unter /media und verlinkt diese'
   echo "   nach ${VIDEO}/_MEDIA_"
   echo
   echo 'Falls -del angegeben ist werden alle links nach <source> unter'
   echo "${VIDEO}/_MEDIA_ gelöscht."
   echo
   echo "Wird als <source> -check angegeben werden alle unter ${VIDEO}/_MEDIA_"
   echo 'verlinkten Aufnahmen die ins Leere zeigen gelöscht.'
   echo
   exit 1
fi

# --- Variablen ---
SOURCE_PATH="$1"
MEDIA_PATH="${VIDEO}/_MEDIA_"
VID_FLS='/tmp/~vidfls'

# --- Funktionen ---
f_linkvid_check() {  # Links löschen, die ins leere zeigen
   echo "Lösche defekte Links unter $MEDIA_PATH"
   find "$MEDIA_PATH" -type l -name '*.rec' -print0 |
      while read -d '' -r i ; do
         LNK="$(readlink "$i")"
         if [[ -z "$LNK" || ! -d "$LNK" ]] ; then
            rm "$i" 2>/dev/null
         fi
      done
   find "$MEDIA_PATH" -type l -name '*.del' -print0 | xargs -0 rm -f
   find "$MEDIA_PATH" -type d -empty -delete  # Leere Verzeichnisse löschen
}

# --- Start ---
[[ ! -d "$MEDIA_PATH" ]] && mkdir -p "$MEDIA_PATH"

if [[ "$1" == "-del" ]] ; then
   echo "Lösche alle Links unter $MEDIA_PATH"
   # find "$MEDIA_PATH" -type l -name '*.rec' -print0 |
   #   while read -d '' -r i ; do
   #      if [[ -n "$2" ]] ; then
   #         LNK="$(readlink "$i")"
   #         if [[ -n "$LNK" && -z "${LNK/*$B*/}" ]] ; then
   #            rm "$i" 2>/dev/null
   #         fi
   #      fi
   #   done
   find "$MEDIA_PATH" -type l -name '*.rec' -delete
   find "$MEDIA_PATH" -type d -empty -delete  # Leere Verzeichnisse löschen
elif [[ "$1" == "-check" ]] ; then
   f_linkvid_check  # Links löschen, die ins leere zeigen
else
   # [[ ! -d "$MEDIA_PATH" ]] && mkdir -p "$MEDIA_PATH"  # Doppelt?
   SOURCE_PATH="${SOURCE_PATH%/}"
   SOURCE_BASE="${SOURCE_PATH##*/}"

   find "$MEDIA_PATH" -name '*.rec' -print0 |
      while read -d '' -r i ; do
         # LNK="$(readlink "$i" | grep "^${SOURCE_PATH}/")"
         # [[ -n "$LNK" ]] && rm "$i" 2>/dev/null
         LNK="$(readlink "$i")"
         [[ "$LNK" =~ ^${SOURCE_PATH}/ ]] && rm "$i" 2>/dev/null
      done
   if [[ "$2" != "-del" ]] ; then
      f_linkvid_check  # Links löschen, die ins leere zeigen
      # Alte *.del Verzeichnisse löschen (Externe Platte)
      find "$SOURCE_PATH" -type d -name '*.del' -print0 | xargs -0 rm -rf
      # Leere Verzeichnisse löschen (Externe Platte)
      find "$SOURCE_PATH" -type d -empty -delete  # Leere Verzeichnisse löschen
      rm "$VID_FLS" 2>/dev/null
      echo "Suche Aufnahmen unter $SOURCE_PATH ..."
      find "$SOURCE_PATH" -name "[12]*.rec" -type d -print0 |
         while read -d '' -r i ; do
            echo "$i" >> "$VID_FLS"
            if [[ -f "${i}/001.vdr" || -f "${i}/00001.ts" ]] ; then
               # DN="$(dirname "$i" | sed -e "s:^$SOURCE_PATH::" | sed -e "s:$VIDEO/:/:")"
               DN="${i%/*}" ; DN="${DN#$SOURCE_PATH}" ; DN="${DN/$VIDEO\//\/}"
               BN="${i##*/}"  # "$(basename "$i")"
               mkdir -p "${MEDIA_PATH}${DN}" 2>/dev/null
               if [[ -f "${MEDIA_PATH}${DN}/${BN}" ]] ; then
                  echo "${MEDIA_PATH}${DN}/${BN} bereits vorhanden"
               else
                  echo "Verlinke $i nach ${MEDIA_PATH}${DN}/"
                  ln -s "$i" "${MEDIA_PATH}${DN}/"
               fi
            fi
         done
   else
      rmdir -p "${MEDIA_PATH}/${SOURCE_BASE}" &>/dev/null
   fi
fi

touch "${VIDEO}/.update"
