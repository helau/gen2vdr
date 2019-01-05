#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
IPS=$(ip addr show | grep " inet.*scope global" | head -n1 |tr -s " "| cut -f 3 -d " ")

glogger -s "Suche nach OctopusNet ..."
nmap $IPS -p 80 -oG - --open |grep "Ports: 80" | cut -f 2 -d " " | while read IP ; do
   [ "$(wget -O - -q "http://${IP}/index.html" | grep -i "octopusnet" 2>/dev/null)" != "" ] && glogger -s "Gefunden: $IP"
done
