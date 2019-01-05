#!/bin/bash
set -x
rm /tmp/initrd/root/.bash_history
umount /tmp/initrd
gzip /tmp/instrd
cp /_config/backup/isolinux/instrd.gz /_config/backup/isolinux/instrd.gz.old
cp /tmp/instrd.gz /_config/backup/isolinux/instrd.gz
