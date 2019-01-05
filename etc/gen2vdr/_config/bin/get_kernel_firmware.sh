#!/bin/bash
cd /tmp
[ -e linux-firmware ] && rm -rf linux-firmware
git clone git://git.kernel.org/pub/scm/linux/kernel/git/dwmw2/linux-firmware.git
cp -av linux-firmware/* /lib/firmware/
rm -rf linux-firmware
get_dvb_firmware 2>&1| grep -v "^[a-zA-Z]" | tr -d "\t" | while read i ; do get_dvb_firmware $i ; done
cp -avf *.fw /lib/firmware/	
cd ..
rm -rf fw
