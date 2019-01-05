#!/bin/bash
SPLIT_START="([{ "
SPLIT_END=":.;!?)]}"

#calculate length
VID_LEN="??:??:??"
if [ -s "${1%info.vdr}index.vdr" ] ; then
   fsize=$(stat -c %s "${1%info.vdr}index.vdr")
   hours=$(($fsize/720000))
   fsize=$(($fsize%720000))
   minutes=$(($fsize/12000))
   [ $minutes -lt 10 ] && minutes="0$minutes"
   fsize=$(($fsize%12000))
   seconds=$(($fsize/200))
   [ $seconds -lt 10 ] && $seconds="0$seconds"
   VID_LEN="$hours:$minutes:$seconds"
fi
SPLIT_CHARS="${SPLIT_START}${SPLIT_END}"
MAX_SPLIT=
if [ "$2" != "" ] ; then
   LINE_LENGTH=$2
else
   LINE_LENGTH=80
fi   
MIN_LENGTH=20
cat "$1" | while read line ; do
   if [ "${line:0:1}" = "T" ] ; then
      echo "${line:2}  ($VID_LEN)"
      echo ""
   elif [ "${line:0:1}" = "D" ] ; then
      line="${line%|}"
      line="${line:2}||"
      while [ "$line" != "" ] ; do
         ln="${line%%|*}"
	 while [ "${ln:0:1}" = " " ] ; do ln="${ln# }" ; done
	 while [ ${#ln} -gt $LINE_LENGTH ] ; do
	     idx=$LINE_LENGTH
	     if [ "${SPLIT_START#*${ln:$idx:1}}" = "$SPLIT_START" ] ; then
	        while [ $idx -ge $MIN_LENGTH ] ; do
                   idx=$(($idx - 1))
                   if [ "${SPLIT_CHARS#*${ln:$idx:1}}" != "$SPLIT_CHARS" ] ; then
		      if [ "${SPLIT_END#*${ln:$idx:1}}" != "$SPLIT_END" ] ; then
		         [ $idx -eq $(($LINE_LENGTH-1)) ] && continue
                         idx=$(($idx + 1))
		      fi	 		         
		      break;
		   fi
		done
		if [ $idx -lt $MIN_LENGTH ] ; then
		   idx=$LINE_LENGTH
		fi   
	     fi	
	     echo "${ln:0:$idx}"
	     ln="${ln:$idx}"
             while [ "${ln:0:1}" = " " ] ; do ln="${ln# }" ; done
	 done
	 echo "$ln"
	 line="${line#*|}"
      done
   elif [ "${line:0:1}" = "X" ] ; then
      if [ "${line:2:1}" = "1" ] ; then
         case "${line:4:2}" in
            01 | 05)
	       fmt="4:3"
	       ;;
	    02 | 03 | 06 | 07)
	       fmt="16:9"
	       ;;
	    04 | 08)
	       fmt=">16:9"
	       ;;
	    09 | 0D)
	       fmt="HD 4:3"
	       ;;
	    0A | 0B | 0E | 0F)
	       fmt="HD 16:9"
	       ;;
	    0C | 10)
	       fmt="HD >16:9"
	       ;;
	    *)
	       fmt="unknown(${line:4:2})"   
	       ;;
	 esac       
         echo "Video: $fmt (${line:7})"
      elif [ "${line:2:1}" = "2" ] ; then
         case "${line:4:2}" in
            01)
	       fmt="Mono"
	       ;;
	    03)
	       fmt="Stereo"
	       ;;
	    05)
	       fmt="Dolby Digital"
	       ;;
	    *)
	       fmt="unknown(${line:4:2})"   
	       ;;
	 esac       
         echo "Audio: $fmt (${line:7})"
      fi	 
   fi
done