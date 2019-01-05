#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x

NOAD_SCRIPT="${VIDEO}/noad.sh"

if [ "$1" = "-init" ] ; then
   # Check for noad tasks to resume
   NOAD_SCRIPT="${VIDEO}/noad.sh"
   if [ -f $NOAD_SCRIPT ] ; then
      find $VIDEO -follow -name noad.pid -type f -print| xargs /bin/rm -f
      screen -dm sh -c "nice -n 10 sh $NOAD_SCRIPT; /_config/bin/g2v_maintain_recordings.sh"
   else      
      screen -dm sh -c "/_config/bin/g2v_maintain_recordings.sh"
   fi
elif [ "$1" = "-exit" ] ; then
   [ -f $NOAD_SCRIPT ] && rm $NOAD_SCRIPT
   # check for noad
   if [ "$(pidof noad)" != "" ] ; then
      for i in $(pidof noad) $(pidof -x /_config/bin/vdrnoad.sh) ; do      
         ps -p $i --noheader -f >> $NOAD_SCRIPT
      done	 
      sed -i $NOAD_SCRIPT -e "s%.* /usr/bin/noad%/usr/bin/noad%" -e "s%.* /_config/bin/vdrnoad%/_config/bin/vdrnoad%" -e "s% ${VIDEO}% \"${VIDEO}%" -e "s%$%\"%"
      kill -9 $(pidof noad) $(pidof -x /_config/bin/vdrnoad.sh)
      find $VIDEO -follow -name noad.pid -type f -print| xargs /bin/rm -f
   fi      
else
   glogger -s "Wrong parameter <$0 $*>"
fi
