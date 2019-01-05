#!/bin/bash
PROXY_HOST=""
PROXY_PORT=""
PROXY="$1"
if [ "$1" = "0" -o "$1" = "off" ] ; then
   PROXY_HOST=""
   PROXY_PORT=""
   PROXY=""
elif [ "$1" != "" ] ; then
   PROXY_HOST="${PROXY%%:*}"
   PROXY_PORT="${PROXY##*:}"
   [ "$PROXY_HOST" = "" -o "$PROXY_PORT" = "" ] && PROXY=""
else
   echo "Syntax: $0 off|PROXY_PORT"
   echo "           PROXY_PORT e.g. 172.16.0.0:8080"
   exit
fi


if [ ! -z $PROXY_HOST ] ; then
   echo "http_proxy=\"$PROXY\"" > /etc/env.d/95proxy
   echo "https_proxy=\"$PROXY\"" >> /etc/env.d/95proxy
   echo "ftp_proxy=\"$PROXY\"" >> /etc/env.d/95proxy
   sed -i /etc/layman/layman.cfg -e "s%[# ]*proxy .*%proxy : http://$PROXY%"
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<httpproxyport>.*</httpproxyport>%<httpproxyport>${PROXY_PORT}</httpproxyport>%" \
       -e "s%<httpproxyserver>.*</httpproxyserver>%<httpproxyserver>${PROXY_HOST}</httpproxyserver>%" \
       -e "s%<usehttpproxy>.*</usehttpproxy>%<usehttpproxy>true</usehttpproxy>%" >/dev/null 2>&1
   sed -i /root/.subversion/servers -e "s/^# http-proxy-host.*/http-proxy-host = ${PROXY_HOST}/" \
                                    -e "s/^# http-proxy-port.*/http-proxy-port = ${PROXY_PORT}/" >/dev/null 2>&1
   sed -i /root/.xine/config* -e "s/.*media.network.http_proxy_host.*/media.network.http_proxy_host:${PROXY_HOST}/" \
                              -e "s/.*media.network.http_proxy_port.*/media.network.http_proxy_port:${PROXY_PORT}/" >/dev/null 2>&1
else
   rm -f /etc/env.d/95proxy
   sed -i /etc/layman/layman.cfg -e "s%[# ]*proxy .*%#proxy : http://172.16.1.0:8080%"
   sed -i /root/.xbmc/userdata/guisettings.xml -e "s%<httpproxyport>.*</httpproxyport>%<httpproxyport></httpproxyport>%" \
       -e "s%<httpproxyserver>.*</httpproxyserver>%<httpproxyserver></httpproxyserver>%" \
       -e "s%<usehttpproxy>.*</usehttpproxy>%<usehttpproxy>false</usehttpproxy>%" >/dev/null 2>&1
   sed -i /root/.subversion/servers -e "s/^http-proxy-host.*/# http-proxy-host = /" \
                                    -e "s/^http-proxy-port.*/# http-proxy-port = /" >/dev/null 2>&1
   sed -i /root/.xine/config* -e "s/.*media.network.http_proxy_host.*/#media.network.http_proxy_host:172.16.0.1/" \
                              -e "s/.*media.network.http_proxy_port.*/#media.network.http_proxy_port:8080/" >/dev/null 2>&1
fi
env-update
source /etc/profile
