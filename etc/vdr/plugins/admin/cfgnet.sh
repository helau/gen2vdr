#!/bin/bash
source /_config/bin/g2v_funcs.sh
NET_SCRIPTS="dhcpcd netmount samba sshd xinetd xxv vdradmin chronyd nfs fritzwatch portmap wicd"
NET_CONF=/etc/conf.d/net

if [ "$NET" == "WiFi" ] && [ ! -e /etc/init.d/wicd ] ; then
   $SETVAL NET "Ja"
   NET=Ja
fi
IFACE=$(ls -d /sys/class/net/*/device |cut -f 5 -d "/" |head -n1)

if [ "$IFACE" = "" ] ; then
   glogger -s "Kein Netzwerkinterface gefunden"
   NET="Nein"
fi

if [ "$NET" = "Nein" ] ; then
   glogger -s "ADMIN - Netzwerk wird deaktiviert"
   for i in $NET_SCRIPTS ; do
      rc-update del ${i} default >/dev/null 2>&1
      rc-update del ${i} boot >/dev/null 2>&1
   done
   for i in /etc/init.d/net.* ; do
      if [ -e $i -a "${i##*.lo}" != "" ] ; then
         rc-update del ${i##*/} boot >/dev/null 2>&1
      fi
   done
   /_config/bin/setproxy.sh off
elif [ "$NET" = "Ja" ] ; then
   glogger -s "ADMIN - Netzwerk wird aktiviert"
   [ ! -e /etc/init.d/net.${IFACE} ] && ln -s net.lo /etc/init.d/net.${IFACE}
   rc-update add net.${IFACE} boot >/dev/null 2>&1
   rc-update del wicd boot >/dev/null 2>&1
   /etc/init.d/wicd stop >/dev/null 2>&1

   mv $NET_CONF $NET_CONF.org
   if [ "$DHCP" = "0" ] ; then
      mv /etc/resolv.conf /etc/resolv.conf.org
      echo "config_${IFACE}=\"$IPADR netmask $SUBNET\"" >$NET_CONF
      if [ "$GATEWAY" != "" ] ; then
         echo "routes_${IFACE}=\"default via $GATEWAY\"" >>$NET_CONF
      fi
      echo "dns_servers_${IFACE}=\"$NAMESERVER\"" >>$NET_CONF
      echo "nameserver $NAMESERVER" > /etc/resolv.conf
      if [ "$DOMAIN" != "" ] ; then
         echo "dns_domain_${IFACE}=$DOMAIN" >>$NET_CONF
      fi
   else
      IPADR=$(ifconfig |tr -s " " | grep "^ inet [0-9]"|cut -f3 -d" "|grep -v "127")
      if [ "$IPADR" != "" ] ; then
         $SETVAL IPADR $IPADR
         NMS=$(grep -m 1 nameserver /etc/resolv.conf | cut -f 2 -d " ")
         [ "$NMS" = "" ] && NMS="192.168.178.1"
         $SETVAL NAMESERVER $NMS
      fi
   fi
   if [ "$WAKEONLAN" = "1" ] ; then
      echo "ifdown_${IFACE}=\"NO\"" >>$NET_CONF
      cat ${NET_CONF}.wol >>$NET_CONF
   fi
   /etc/init.d/net.${IFACE} start >/dev/null 2>&1
   glogger -s "ADMIN - WAKEONLAN: $WAKEONLAN"
elif [ "$NET" = "WiFi" ] ; then
   glogger -s "ADMIN - Wicd wird aktiviert"
   for i in /etc/init.d/net.* ; do
      if [ -e $i -a "${i##*.lo}" != "" ] ; then
         rc-update del ${i##*/} boot >/dev/null 2>&1
         $i stop >/dev/null 2>&1
      fi
   done
   /etc/init.d/wicd start >/dev/null 2>&1
   rc-update add wicd boot >/dev/null 2>&1
#   mv $NET_CONF $NET_CONF.org
   if [ "$DHCP" = "0" ] ; then
      mv /etc/resolv.conf /etc/resolv.conf.org
      cat /etc/wicd/wired-settings.conf.fixed | \
          sed -e "s%^gateway .*%gateway = $GATEWAY%" \
              -e "s%^ip .*%ip = $IPADR%" \
              -e "s%^netmask .*%netmask = $SUBNET%" \
              -e "s%^dns1 .*%dns1 = $NAMESERVER%" > /etc/wicd/wired-settings.conf
   else
      cp /etc/wicd/wired-settings.conf.dhcp /etc/wicd/wired-settings.conf
      IPADR=$(ifconfig |tr -s " " | grep "^ inet [0-9]"|cut -f3 -d" "|grep -v "127")
      if [ "$IPADR" != "" ] ; then
         $SETVAL IPADR $IPADR
         NMS=$(grep -m 1 nameserver /etc/resolv.conf | cut -f 2 -d " ")
         [ "$NMS" = "" ] && NMS="192.168.178.1"
         $SETVAL NAMESERVER $NMS
      fi
   fi
else
   glogger -s "ADMIN - Netzwerk wird manuell konfiguriert"
fi

if [ "$NET" = "Ja" ] || [ "$NET" == "WiFi" ] ; then
   rc-update add netmount default >/dev/null 2>&1
   rc-update add portmap default >/dev/null 2>&1

   echo "/etc/conf.d/hostname wird angepasst"
   echo "hostname=$HOSTNAME" > /etc/conf.d/hostname
   hostname $HOSTNAME
   if [ "$(grep "127\.0\.0\.1" /etc/hosts | grep $HOSTNAME)" = "" ] ; then
      sed -i /etc/hosts -e "/127\.0\.0\.1/d"
      echo "127.0.0.1   localhost" >> /etc/hosts
      echo "127.0.0.1   $HOSTNAME" >> /etc/hosts
   fi
   sed -i /etc/samba/smb.conf -e "s/netbios name = .*\$/netbios name = $HOSTNAME/"
   if [ "$(grep "^ServerName" /etc/apache2/httpd.conf 2>/dev/null)" != "" ] ; then
      sed -i /etc/apache2/httpd.conf -e "s/^ServerName.*/ServerName $HOSTNAME/"
   else
      [ -e /etc/apache2/httpd.conf ] && echo "ServerName $HOSTNAME" >> /etc/apache2/httpd.conf
   fi
   /_config/bin/setproxy.sh "${PROXY_HOST}:${PROXY_PORT}"

   IPRANGE=${IPADR}
   IPREST=""
   IPRLEN=32
   SN=$SUBNET
   while [ "${SN%\.0}" != "$SN" ] ; do
      IPRLEN=$(($IPRLEN-8))
      IPREST="${IPREST}.0"
      SN=${SN%\.0}
      IPRANGE=${IPRANGE%\.*}
   done

   echo "/etc/vdr/svdrphosts.conf wird angepasst"
   sed -i /etc/vdr/svdrphosts.conf \
       -e "/# local subnet/d"

   echo "$IPRANGE$IPREST/$IPRLEN   # local subnet" >> /etc/vdr/svdrphosts.conf

   if [ "$SAMBA" = "0" ] ; then
      rc-update del samba default >/dev/null 2>&1
      /etc/init.d/samba stop
   else
      rc-update add samba default >/dev/null 2>&1
      echo "/etc/samba/smb.conf wird angepasst"
      sed -i /etc/samba/smb.conf -e "s/hosts allow = .*/hosts allow = $IPRANGE./"
      sed -i /etc/samba/smb.conf  -e "s/workgroup = .*/workgroup = $WORKGROUP/"
      /etc/init.d/samba restart
   fi
   glogger -s "ADMIN - Samba: $SAMBA"

   if [ "$SSH" = "0" ] ; then
      rc-update del sshd default >/dev/null 2>&1
      /etc/init.d/sshd stop >/dev/null 2>&1
   else
      rc-update add sshd default >/dev/null 2>&1
      /etc/init.d/sshd start >/dev/null 2>&1
   fi
   glogger -s "ADMIN - SSH: $SSH"

   if [ "$NFS" = "0" ] ; then
      rc-update del nfs default >/dev/null 2>&1
      /etc/init.d/nfs stop >/dev/null 2>&1
   else
      if [ "$NFS_RO" = "0" ] ; then
         sed -i /etc/exports -e "s/*(ro,/*(rw,/"
      else
         sed -i /etc/exports -e "s/*(rw,/*(ro,/"
      fi

      rc-update add nfs default >/dev/null 2>&1
      /etc/init.d/nfs start >/dev/null 2>&1
   fi
   glogger -s "ADMIN - NFS: $NFS"
   sed -i /etc/xinetd.conf -e "s%only_from.*%only_from = 127.0.0.0/24 ${IPRANGE}${IPREST}/${IPRLEN}%"
   if [ "$FTP" = "0" ] ; then
      /etc/init.d/xinetd stop >/dev/null 2>&1
      sed -i /etc/xinetd.d/ftp -e "s/disable.*/disable = yes/"
      rc-update del xinetd default >/dev/null 2>&1
   else
      rc-update add xinetd default >/dev/null 2>&1
      sed -i /etc/xinetd.d/ftp -e "s/disable.*/disable = no/"
      /etc/init.d/xinetd start >/dev/null 2>&1
   fi
   glogger -s "ADMIN - FTP: $FTP"

   if [ "$NTP" = "0" ] ; then
      rc-update del chronyd default >/dev/null 2>&1
      /etc/init.d/chronyd stop
   else
      rc-update add chronyd default >/dev/null 2>&1
      /etc/init.d/chronyd start
   fi
   glogger -s "ADMIN - NTP(Uhrzeit per Internet): $NTP"

   if [ "$FRITZWATCH" = "1" ] ; then
      rc-update add fritzwatch default >/dev/null 2>&1
      /etc/init.d/fritzwatch start >/dev/null 2>&1
   else
      /etc/init.d/fritzwatch stop >/dev/null 2>&1
      rc-update del fritzwatch >/dev/null 2>&1
   fi

   if [ "$VDRADMIN" = "1" ] ; then
      rc-update add vdradmin default >/dev/null 2>&1
      /etc/init.d/vdradmin start >/dev/null 2>&1
   else
      /etc/init.d/vdradmin stop >/dev/null 2>&1
      rc-update del vdradmin >/dev/null 2>&1
   fi
else
   glogger -s "ADMIN - Netzwerk wird manuell konfiguriert"
fi
