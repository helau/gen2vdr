#!/bin/bash
PKGS=$(cat /mnt/data/portage/packages/g2v.pkg |sed -e "s/^/=/" 2>/dev/null)
logger -s "emerge -v --usepkgonly $PKGS"
emerge -pv --usepkgonly $PKGS
