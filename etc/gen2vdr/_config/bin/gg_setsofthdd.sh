#!/bin/bash
source /_config/bin/g2v_funcs.sh >/dev/null 2>&1
[ "${1,,}" == "deta" ] && [ "${PLUGINS/*skindesigner*/}" == "" ] && svdrpsend PLUG skindesigner DLIC >/dev/null 2>&1
[ "${PLUGINS/*softhddevice*/}" == "" ] && svdrpsend PLUG softhddevice $1
[ "${PLUGINS/*vaapidevice*/}" == "" ]  && svdrpsend PLUG vaapidevice $1
#/usr/local/bin/vdr-dbus-send.sh /Plugins/softhddevice plugin.SVDRPCommand string:'$1' string:''
