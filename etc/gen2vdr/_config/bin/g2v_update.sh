#!/bin/bash
layman -S
eix-sync -v
echo "Press enter for: emerge -auvDN --with-bdeps=y world"
read
emerge -auvDN --with-bdeps=y world
echo "Press enter for: smart-live-rebuild -- -av"
read
etc-update
smart-live-rebuild -- -av
echo "Press enter for: emerge -av --depclean"
read
emerge -av --depclean
cat /_config/backup/README.update
