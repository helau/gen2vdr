#!/bin/bash
cd /tmp
[ -e snd ] && rm -rf snd
mkdir snd

aplay -lL > snd/aplay
for i in /proc/asound/card[0-9] ; do
   cnum=${i#*card}
   amixer contents  -c $cnum > snd/amixerc.$cnum
   amixer scontents -c $cnum > snd/amixers.$cnum
   alsactl store $cnum
done
cp /etc/vdr/setup.conf snd/
cp /root/.xine/config snd/
cp /root/.xine/config_xineliboutput snd/
cp /etc/asound.conf snd/
cp /etc/asound.state snd/
cp /etc/vdr.d/conf/vdr snd/

tar -czvf snd.tgz snd/*
rm -rf snd

echo ""
echo "Und nun sende /tmp/snd.tgz an <helmut at helmutauer dot de>"
echo "mit nem kurzen Kommentar zur Soundkarte/geanderten Einstellungen :)"
