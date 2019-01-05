#!/bin/bash
mkdir -p ~/.kodi/cdm
cd ~/.kodi/cdm

[ -f libwidevinecdm.so ] && mv -vf libwidevinecdm.so libwidevinecdm.so.bak
echo "Downloading: libwidevinecdm.so..."
#curl -Lf --progress-bar --url http://www.slimjetbrowser.com/chrome/lnx/chrome64_55.0.2883.75.deb -o temp.deb
curl -Lf --progress-bar --url https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o temp.deb
ar xv temp.deb data.tar.xz 
#ar xv chrome64_55.0.2883.75.deb data.tar.xz
echo "Extracting libwidevinecdm.so..." 
tar xvJfO data.tar.xz ./opt/google/chrome/libwidevinecdm.so > libwidevinecdm.so 
chmod 755 libwidevinecdm.so
rm -vf temp.deb data.tar.xz
[ -f libwidevinecdm.so ] &&  echo "Successfully installed libwidevinecdm.so!" ||  echo "ERROR: Unable to install libwidevinecdm.so"
