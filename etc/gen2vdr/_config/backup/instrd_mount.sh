#!/bin/bash
set -x
cp /_config/backup/isolinux/instrd.gz /tmp
gzip -d /tmp/instrd.gz
mkdir /tmp/initrd 2>/dev/null
rm -rf /tmp/initrd/* 2>/dev/null
mount /tmp/instrd /tmp/initrd/ -o rw,loop
