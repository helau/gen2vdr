# This file has to be included via source command
# VERSION=170402

trap g2v_exit EXIT

SELF="$(readlink /proc/$$/fd/255)" || SELF="$0"  # Eigener Pfad (Besseres $0)
SELF_NAME="${SELF##*/}"                          # Eigener Name mit Erweiterung

[[ -z "$LOG_LEVEL" ]]   && source /etc/vdr.d/conf/vdr
[[ -z "$RUNVDR_INIT" ]] && source /etc/vdr.d/conf/gen2vdr.cfg

g2v_exit() {
   # Your cleanup code here
   glogger 'Script ends'
}

glogger() {
   if [[ "$LOG_LEVEL" != '0' ]] ; then
      if [[ "$1" == '-s' ]] ; then
         PARM='-s'
         shift
      elif [[ "$1" == '-o' ]] ; then
         PARM='-s'
         shift
         vdr-dbus-send.sh /Skin skin.QueueMessage string:"\"$*\""
      else
         PARM=''
      fi
      logger "$PARM" -t "G2V_$$_$PPID" "$SELF" "$*"
   fi
}

strstr() {
   # strstr echoes nothing if s2 does not occur in s1
   [[ -n "$2" && -z "${1/*$2*}" ]] && return 0
   return 1
}

svdrps() {
   glogger "svdrpsend $*"
   /usr/bin/svdrpsend.sh "$@"
}

glogger 'Script starts'
