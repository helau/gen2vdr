#!/bin/bash
PATTERN=$1
COMMAND=$2

if [ "$3" != "" ] && [ -f $3 ] ; then
   FILE=$3
else
   FILE=/log/messages
fi

IC=$(grep "$PATTERN" "$FILE" |wc -l)
while [ 1 ]; do
   NC=$(grep "$PATTERN" "$FILE" |wc -l)
   if [ $NC != $IC ] ; then
      echo "Executing <$COMMAND>"
      $COMMAND
      IC=$NC
   fi
   sleep 3
done
