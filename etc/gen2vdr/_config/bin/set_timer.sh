#!/bin/bash
source /_config/bin/g2v_funcs.sh
#
# This script was made by Helmut Auer
# based on the set_timer.sh from nvram-wakup packet
# written by Hans-Hermann Redenius (redenius@gmx.de)
#
# This file is for bioses nvram-wakeup couldn't handle, because there is
# no possibility to chamge the Wake on RTC time in the nvram
# The wake up time must be set to 23:59:59 the day must be set to 31
# if your board supports a month setting for the wakeup, set it to July
# if your board supports a year setting for the wakeup, set it to 2008
# 
#set -x

NEXT_TIMER=$1

hwc_parms="--noadjfile"
[ "$DIRECTISA" = "1" ] && hwc_parms="$hwc_parms --directisa"
source /etc/conf.d/hwclock
glogger -s "$0"
if [ "$CLOCK" != "local" ] ; then
   hwc_parms="$hwc_parms --utc"
else
   hwc_parms="$hwc_parms  --localtime"
fi
[ -f /etc/adjtime ] && rm -f /etc/adjtime

# files to use:
TIME_DIFF=/_config/status/time_diff

if [ "$NEXT_TIMER" = "" ] ; then
   # if a time_diff file exists the clock is set to the wakeup time and
   # must be fixed before any further action
   #
   if [ -s $TIME_DIFF ] ; then
      # the difference stored 
      hwclock $hwc_parms --hctosys
      sleep 1
      cur_time="$(date +%s)"
      time_diff="$(cat $TIME_DIFF)"
      # add the difference to the curent time and change it in the date format
      time_to_set=$(($cur_time + $time_diff))
      date -s "1970-01-01 UTC $time_to_set seconds"
      sleep 1
      hwclock $hwc_parms --systohc
      glogger -s "$0 1 - $time_to_set-$cur_time-$time_diff"
      rm -f $TIME_DIFF
   fi
else
   # if there is a parameter given, it is assumed the system should boot 
   # after $boot_time seconds 
   if [ "$NEXT_TIMER" != "0" ] ; then
      cur_time="$(date +%s)"
      wake_time="$(date -d "Jul 31 23:59:59 2008" +%s)"
      sleep_time=$(($NEXT_TIMER - $cur_time))
      time_to_set=$(($wake_time - $sleep_time))
      hwclock $hwc_parms --set --date "1970-01-01 UTC $time_to_set seconds"
      hw_time="$(date -d "1970-01-01 UTC $time_to_set seconds")"
      # calculate the right time and the time difference
      time_diff=$(($cur_time - $time_to_set))
      echo "$time_diff" > $TIME_DIFF
      glogger -s "$0 2 - $time_to_set-$wake_time-$sleep_diff-$time_diff"
   else
      [ -f $TIME_DIFF ] && rm -f $TIME_DIFF
   fi
fi
glogger -s "$0 exit"
