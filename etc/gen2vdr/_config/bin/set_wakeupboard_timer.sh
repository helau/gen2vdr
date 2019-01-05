#!/bin/bash
##### Wakeup Modul Zeit und Timer Setzen
COMPORT="/dev/ttyS0"

/etc/init.d/lircd stop > /dev/null 2>&1
/etc/init.d/freevo stop > /dev/null 2>&1

setserial $COMPORT uart 16550A

TIMESTR=`date +%H%M%S%d%m%y%w`
echo RTS$TIMESTR > /dev/ttyS0

WAKEUPSTR=$(date -d "1970-01-01 $1 seconds UTC" +%H%M%d%m)
echo ATS$WAKEUPSTR  > /dev/ttyS0
logger -s "Wakeup time set to <$WAKEUPSTR>"

