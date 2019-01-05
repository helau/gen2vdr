#!/bin/bash
ls -d /var/db/pkg/*/* |cut -f 5,6 -d "/" > /g2v.pkgs
readlink /usr/local/src/VDR > /g2v.vdr
find /usr/local/src/VDR/PLUGINS/src -type d |cut -f 8 -d "/"|sort -u >> /g2v.vdr
