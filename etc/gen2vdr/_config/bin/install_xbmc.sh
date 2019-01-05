#!/bin/bash

# set -x

source /etc/make.conf

cd $HOME
if  [ ! -L .xbmc ] ; then
 cp .xbmc/userdata/Lircmap.xml $HOME
 mv .xbmc .xbmc_portage
 ln -svfn .xbmc_portage .xbmc
fi

case $1 in

   -e|e)
    CHECK="$(date -r /var/cache/eix/portage.eix +%s)"
    DATE="$(date +%s)"
    [ $((DATE-CHECK)) -gt 86400 ] && eix-sync
    cd $HOME
    ln -svfn .xbmc_portage .xbmc
    emerge -av xbmc || exit
    sed -i /_config/bin/xbmc_start.sh -e 's/^XBMC_DIR.*/XBMC_DIR=\"\/usr\"/'
    exit
   ;;

   -o|o)
    REPO="opdenkamp"
    REPO2="${REPO}-git"
   ;;

   -p|p)
    REPO="pipelka"
    REPO2="${REPO}-git"
   ;;

   -x|x)
    REPO="xbmc"
    REPO2="${REPO}-git"
   ;;

   *)
    echo "usage: [-o] [-p] [-x] [-e]"
    echo ""
    echo "	-o  = Opdenkamp" 
    echo "	-p  = Pipelka"
    echo "	-x  = xbmc"
    echo "	-e  = ebuild"
    echo ""
    exit
   ;;

esac

echo ""

vdr-plugin-xvdr ()
{

cd /usr/local/src/VDR/PLUGINS/src

if [ -d xvdr/.git ] ; then
  cd xvdr
  original_head=$(git rev-parse HEAD) || exit 
  git pull || exit 
  updated_head=$(git rev-parse HEAD) || exit 
  if [ $original_head == $updated_head ] ; then
    LOOP=0 
    while [ $LOOP -eq 0 ] 
    do 
      echo -en 'vdr-plugin-xvdr ist aktuell, soll das vdr-plugin-xvdr trotzdem neu compiliert werden? [yes/no]: ' 
      read CHOICE 
      echo -en "\n" 
     case $CHOICE in 

       [yY][eE][sS]|[yY])  
        echo "vdr-plugin-xvdr wird neu compiliert ..." 
        LOOP=1 ;; 
  
       [nN][oO]|[nN])
        exit
        LOOP=1 ;; 
        
       *) echo "Bitte \"yes\" oder \"no\" eingeben." 
        LOOP=0;; 
 
     esac 
    done
  fi
else
  git clone git://github.com/pipelka/vdr-plugin-xvdr.git xvdr-git
  ln -s xvdr-git xvdr
  cd xvdr
fi

make clean
make $MAKEOPTS


if [ "$?" = "0" ] ; then
  /_config/bin/instvdr.sh
 else
  echo ""
  echo "Error while compiling vdr-plugin-xvdr"
  exit
fi
exit
}


xbmc-addon-xvdr ()
{

cd /opt/XBMC
if [ -d /opt/XBMC/xbmc-addon-xvdr/.git ] ; then
  cd xbmc-addon-xvdr
  original_head=$(git rev-parse HEAD) || exit 
  git pull || exit 
  updated_head=$(git rev-parse HEAD) || exit 
  if [ $original_head == $updated_head ] ; then
    LOOP=0 
    while [ $LOOP -eq 0 ] 
    do 
      echo -en 'xbmc-addon-xvdr ist aktuell, soll das xbmc-addon-xvdr trotzdem neu compiliert werden? [yes/no]: ' 
      read CHOICE 
      echo -en "\n" 
     case $CHOICE in 

       [yY][eE][sS]|[yY])  
        echo "xbmc-addon-xvdr wird neu compiliert ..." 
        LOOP=1 
        ;; 
  
        [nN][oO]|[nN])
         vdr-plugin-xvdr
         LOOP=1 
         ;; 
        
       *) echo "Bitte \"yes\" oder \"no\" eingeben." 
        LOOP=0
        ;; 
 
     esac 
    done
  fi
else
  git clone git://github.com/pipelka/xbmc-addon-xvdr.git xbmc-addon-xvdr  
  cd xbmc-addon-xvdr
fi

sh autogen.sh
./configure --prefix=/opt/XBMC/appl/share/xbmc

make clean
make $MAKEOPTS

if [ "$?" = "0" ] ; then
  make install
 else
  echo ""
  echo "Error while compiling xbmc-addon-xvdr"
  exit
fi
}


[ ! -d /opt/XBMC/${REPO2} ] && mkdir -pv /opt/XBMC/${REPO2}
cd /opt/XBMC

if [ -d /opt/XBMC/${REPO2}/.git ] ; then
  cd ${REPO2}
  original_head=$(git rev-parse HEAD) || exit 
  git pull || exit 
  updated_head=$(git rev-parse HEAD) || exit 
  if [ $original_head == $updated_head ] ; then
    LOOP=0 
    while [ $LOOP -eq 0 ] 
    do 
      echo -en "${REPO2} ist aktuell, soll xbmc trotzdem neu compiliert werden? [yes/no]: " 
      read CHOICE 
      echo -en "\n" 
     case $CHOICE in 

       [yY][eE][sS]|[yY])  echo "${REPO2} wird neu compiliert ..." 
       LOOP=1 ;; 
  
       [nN][oO]|[nN])
       xbmc-addon-xvdr
       LOOP=1 ;; 
        
       *) echo "Bitte \"yes\" oder \"no\" eingeben." 
       LOOP=0;; 
 
     esac 
    done
  fi
else
  git clone git://github.com/${REPO}/xbmc.git  ${REPO2}
  cd ${REPO2}
fi

./bootstrap
./configure --prefix=/opt/XBMC/${REPO2}_appl --disable-hal --disable-crystalhd

make clean
make $MAKEOPTS

if [ "$?" = "0" ] ; then
  make install
  cd $HOME
  ln -sfvn /opt/XBMC/${REPO2}_appl/share/xbmc .xbmc_${REPO2}
  ln -sfvn .xbmc_${REPO2} .xbmc
  cd /opt/XBMC
  ln -sfnv ${REPO2}_appl appl
  sed -i /_config/bin/xbmc_start.sh -e 's/^XBMC_DIR.*/XBMC_DIR=\"\/opt\/XBMC\/appl\"/'
  cd ${REPO2}_appl/share/xbmc
  if [ ! -d userdata ] ; then
   DISPLAY=:0 /opt/XBMC/appl/bin/xbmc &
   sleep 3
   killall -KILL xbmc
   cp -v $HOME/Lircmap.xml userdata/Lircmap.xml
   /etc/init.d/g2vgui stop && /etc/init.d/g2vgui start
  fi
else
  echo ""
  echo "Error while compiling xbmc"
  exit
fi

