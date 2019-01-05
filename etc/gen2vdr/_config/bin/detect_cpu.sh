#!/bin/bash
NUM_CPUS=$(grep -c "^processor" /proc/cpuinfo)
[ "$NUM_CPUS" = "" ] && NUM_CPUS=1
sed -i /etc/portage/make.conf -e "s/^MAKEOPTS=.*/MAKEOPTS=\"-j$((NUM_CPUS+1))\"/"
/etc/init.d/cpupower start
[ -e /sys/devices/system/cpu/cpufreq ] && rc-update add cpupower default
