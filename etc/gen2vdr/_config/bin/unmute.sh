#!/bin/bash
set -x
for i in /proc/asound/card[0-9] ; do
 cNum=${i#*card}
 amixer -c $cNum -s -q <<EOF
   set Master 75% unmute
   set 'Master Mono' 75% unmute
   set Front 75% unmute
   set PCM 90% unmute
   set Line 90% unmute
   mixer Synth 90% unmute
   mixer CD 90% unmute
   # mute mic
   set Mic 0% mute
   # ESS 1969 chipset has 2 PCM channels
   set PCM,1 90% unmute
   # Trident/YMFPCI/emu10k1
   set Wave 100% unmute
   set Music 100% unmute
   set AC97 100% unmute
   # CS4237B chipset:
   set 'Master Digital' 75% unmute
   # Envy24 chips with analog outs
   set DAC 90% unmute
   set DAC,0 90% unmute
   set DAC,1 90% unmute
   # some notebooks use headphone instead of master
   set Headphone 75% unmute
   set Playback 100% unmute
   # turn off digital switches
   set "SB Live Analog/Digital Output Jack" off
   set "Audigy Analog/Digital Output Jack" off
   # turn on digital out for acticvy
   set Speaker 90% unmute
   set Speaker,1 90% unmute
   set Speaker,3 90% unmute
   set IEC958 unmute
   set IEC958,1 unmute
   set 'IEC958 Default PCM' unmute
EOF
 amixer -c $cNum scontrols | grep IEC958 | while read j ; do
   amixer -c $cNum set "${j#Simple mixer control }" unmute
 done
done
