#!/bin/bash

PLUGINDIR="/usr/local/src/VDR/PLUGINS"

cd $PLUGINDIR/..
anzahl=`ls $PLUGINDIR/src | grep -v '[^a-z0-9]' | wc -l`
version_vdr=`egrep '.*APIVERSION.*"' config.h | sed -e 's/.* "//' |  sed -e 's/[";]//g' | tr -d '\015' | tr -d '\012'`

echo "Es folgt eine Liste von $anzahl Plugins"
echo "Kennzeichen * --> übersetzt für VDR-Version $version_vdr"
echo "Kennzeichen ! --> nicht übersetzt (läst sich nicht übersetzen?)"
echo
echo "Plugin-Name                 Version (Version von Verzeichniss) / Hinweis"
echo
#set -x
for i in $(ls $PLUGINDIR/src | grep -v '[^a-z0-9]') ; do
#for i in $(ls $PLUGINDIR/src | grep -v '[^r]') ; do
#for i in restfulapi ; do
  pn=""
  vs=""
  cd $PLUGINDIR/src/$i
#  plugin_name=`egrep -m1 '^[[:space:]]*PLUGIN[1=[:space:]]' $PLUGINDIR/src/$i/Makefile | sed -e 's/[\t ]*PLUGIN.*=//' | sed -e 's/#.*//' | sed -e 's/ //g'`
  if [ -s Makefile ] ; then 
     pn=$(egrep -m1 "^[[:space:]]*PLUGIN[1=[:space:]]" Makefile | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d " ")
#  vs=$(egrep -m1 "^[[:space:]]*VERSION[1=[:space:]]" Makefile | cut -f 2- -d "=" | sed -e "s/^[ \t]*//")
     vs=$(egrep -m1 "^[[:space:]]*VERSION[1=[:space:]]" Makefile | cut -f 2- -d "=" | sed -e "s/^[ \t]*//")
     [ "$vs" = "" ] && vs=$(egrep -m1 "^[[:space:]]*VERSION[1=[:space:]]" Make.config | cut -f 2- -d "=" | sed -e "s/^[ \t]*//")
  fi
  case $i in
     mailbox)     vs=${vs/\$(PLUGINMAINSRC)/AxPluginMailBox.cpp};;
     servicedemo) vs=${vs/\$(PLUGIN1)/svccli};;
     epg2vdr|graphtftng|osd2web|squeezebox|scraper2vdr)   vs=${vs/\$(HISTFILE)/HISTORY.h};;
     upnp)        vs=${vs/\$(ROOTBUILDDIR)/.};;
     wirbelscan) pn="wirbelscan"
  esac
  if [ "$pn" = "" ] ; then
     pn=$i
  fi
  ct=1
  while [ "${vs}" != "" -a "${vs##*\\}" = "" ] ; do
     vsn=$(egrep -m1 -A$ct "^[[:space:]]*VERSION[1=[:space:]]" Makefile | tail -n 1)
     ct=$((ct+1))
     vs="${vs%\\}$vsn"
  done
  vs=${vs/\$(PLUGIN)/$pn}
  vs=${vs/\$PLUGIN/$pn}
  vs=${vs/VERSION \*=/VERSION.\*=}
  vs=${vs//\$\$/$}
  if [ "${vs:0:2}" = "\$(" ] ; then
     vsx=${vs:2}
     vsx=${vsx%)}
     vsx=${vsx#shell}
     vs=$(echo "${vsx}" > /tmp/.cmd; sh /tmp/.cmd)
     if [ "$vs" = "" ] ; then
        vsx=${vsx/$pn.c/$pn.h}
        vs=$(echo "${vsx}" > /tmp/.cmd; sh /tmp/.cmd)
#        vs=$(eval ${vsx})
     fi
  fi
#  if [ "$pn" = "" -o "$vs" = "" ] ; then
#     echo "$PLUGINDIR/src/$i/Makefile: <$pn> <$vs>"
#     echo "$vsx"
#  fi
  plugin_versiondir=""
  if [ -L $PLUGINDIR/src/$i ]; then
    plugin_versiondir=`readlink $PLUGINDIR/src/$i | sed -e 's/.*\///g'`
    plugin_versiondir="${plugin_versiondir:${#pn}:255}"
    plugin_versiondir="${plugin_versiondir:1:255}"
  fi
  if [ -z "$plugin_versiondir" ]; then
    plugin_versiondir="N/A"
  fi
  plugin_libs=1
  case "$pn" in
    mp3)         plugin_libname="mp3 mplayer"
                 plugin_libs=2;;
    streamdev)   plugin_libname="streamdev-client streamdev-server"
                 plugin_libs=2;;
    servicedemo) plugin_libname="svccli svcsvr"
                 plugin_libs=2;;
  esac
  plugin_anzahl=`ls -d $PLUGINDIR/src/$i-* 2>/dev/null | wc -l`
  if [ $plugin_libs = 1 ] ; then
     if [ -r $PLUGINDIR/lib/libvdr-$pn.so.$version_vdr ]; then
       echo -n "* "
     else
       echo -n "! "
     fi
  else
     echo -n "X "
  fi
  echo $pn $vs $plugin_versiondir $plugin_anzahl | awk '{ printf "%-25s %s", $1, $2; if ($2 != $3 && $3 != "N/A") printf " (%s)", $3; if ($4 > 1) printf " es sind %d Versionen vorhanden", $4; printf "\n"; }'

  if [ $plugin_libs -gt 1 ] ; then
     for j in $plugin_libname ; do
        if [ -r $PLUGINDIR/lib/libvdr-$j.so.$version_vdr ]; then
          echo " * $j"
        else
          echo " ! $j"
        fi
     done
  fi
  if [ -z "$pn" ]; then
    echo "Fehler: kein pn für Verzeichniss $i" >&2
  fi
done
