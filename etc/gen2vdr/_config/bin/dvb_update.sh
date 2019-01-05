#!/bin/bash
cd /tmp
git clone "https://github.com/DigitalDevices/dddvb.git"
cd dddvb
CPUS=$(grep -c "^processor" /proc/cpuinfo)
JC=$((CPUS + 2))
make -j $JC
make install
depmod -a
