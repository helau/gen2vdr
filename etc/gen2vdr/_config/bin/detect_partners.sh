#!/bin/bash
source /_config/bin/g2v_funcs.sh
#set -x
# set it to cifs/smbfs/nfs

FSTYPES="cifs nfs"
MOUNTPOINTS="audio video pictures film"
USER="root"
PW="gen2vdr"

PIP="$(grep "hosts all" /etc/samba/smb.conf | sed -e "s/.*=//" | tr -d " ")"
if [ "$PIP" = "" ] ; then
   glogger -s "Keine Partner-IP in smb.conf gefunden"
   exit
fi
PARTNERS="$(grep $PIP /etc/hosts | sed -e "s/.*$PIP//" | tr "\t" " " | tr -s " " | cut -f 2 -d " ")"
if [ "$PARTNERS" = "" ] ; then
   glogger -s "Keine Partner in /etc/hosts gefunden"
   exit
fi

if [ "$1" = "-d" ] ; then
   for i in $MOUNTPOINTS ; do
      for j in $(mount |grep "/${i} on"|  cut -f 1 -d " ") ; do 
         echo "Trenne <$j>"
         umount $j
      done
   done
else
   for i in $PARTNERS ; do
      [ "$i" = "$HOSTNAME" ] && continue
      if ( ping -c1 -t2 $i ) ; then
         echo "Verbinde ${i}"
         for j in $MOUNTPOINTS ; do
            mkdir -p /mnt/$i/${j} > /dev/null 2>&1
            for k in $FSTYPES ; do
               if [ "$k" = "nfs" ] ; then
                  mount -t nfs -o intr ${i}:/${j} /mnt/$i/${j}
                  rc=$?
               else
                  mount -t $k -o username=$USER,password=$PW //${i}/${j} /mnt/$i/${j}
                  rc=$?
               fi
               [ "$rc" = "0" ] && break
            done
            if [ "$rc" = "0" ] ; then
               glogger -s "$i/$j erfolgreich ueber $k verbunden"
               rm -f /$j/_SRV_$i > /dev/null 2>&1
               ln -s /mnt/$i/${j} /$j/_SRV_$i
            else
               glogger -s "Fehler $rc beim mounten von $i/$j ($k)"
            fi
         done
      else
         glogger -s "$i ist nicht online"
      fi
   done
fi
touch $VIDEO/.update
