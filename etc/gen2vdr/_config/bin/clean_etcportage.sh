#!/bin/bash
KODI=/etc/portage/package.keywords/kodi
KL=$(readlink $KODI)
rm $KODI
for i in /etc/portage/package.* ; do
   mkdir -p /tmp/p1${i}
   grep -hv "^#" $i/* | sort -d -u | while read j ; do
      k=${j#[<>=]}
      k=${k#[<>=]}
      echo "$j" >> /tmp/p1${i}/${k%%[/-]*}
   done
done
ln -sf $KL $KODI
ln -sf $KL /tmp/p1${KODI}
mkdir /tmp/p2
set -x
mv -v /etc/portage/package.* /tmp/p2/
mv -v /tmp/p1/etc/portage/package.* /etc/portage/
for i in /etc/portage/package.* ; do
   diff -ruN $i /tmp/p2/${i##*/}
done
