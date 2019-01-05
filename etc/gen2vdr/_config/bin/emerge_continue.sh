#!/bin/bash
# Log everything
LOG_FILE="/log/$(basename ${0%.*}).log"
rm -f "$LOG_FILE"
echo "Started at: $(date +'%F %R')" > ${LOG_FILE}
exec 1> >(tee -a ${LOG_FILE}) 2>&1

#emerge -uvDN $(cat /var/lib/portage/world.g2v /var/lib/portage/world |sort -u)
while [ "$(pidof python3.5)" != "" ] ; do
   sleep 30
done

#emerge -e @world
until emerge --resume --skipfirst ; do
   emerge --resume --skipfirst
done
emerge -v @preserved-rebuild
revdep-rebuild -i
/_config/bin/build-vdr2.sh -a
#halt
exit
