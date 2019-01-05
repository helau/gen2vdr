#!/bin/bash

function GetValue
{
  shopt -s extglob

  if [ -z "$1" -o -z "$2" ]; then
    echo ""
    return 1
  fi

  Label=$1
  Text=$2

  Value=${!Label/*${Text}*( )}
  echo ${Value%%$'\n'*}
}

if [ -f /forcefsck ] ; then
   echo "FSCheck forced"
   FSCK_FORCE=1
else
   echo "FSCheck not forced"
   FSCK_FORCE=0
fi
ERROR=0

# /etc/fstab zeilenweise einlesen
while read Fstab; do
  if [ "${Fstab%%/dev/s*}" != "" ] && [ "${Fstab%%/dev/h*}" != "" ] ; then
#     echo "Ignoring $Fstab"
     continue
  fi
  # Zeile in die einzelnen Felder auftrennen
  set -- ${Fstab}
  Drive=$1
  Mountpoint=$2
  if [ "${Mountpoint%%/*}" != "" ] ; then
     echo "Ignoring $Fstab"
     continue
  fi
  FsType=$3
  FsOptions=$4

  if [ -z "${FsOptions/*noauto*}" ]; then
    echo "Ignoring $Fstab"
    RM_FSCK=1
    continue
  elif [ "${FsType}" = "ext3" -o "${FsType}" = "ext2" ]; then
    FsInfo="$(LANG=C tune2fs -l ${Drive})"
    Mounts=$(GetValue FsInfo "Mount count:")
    MaxMounts=$(GetValue FsInfo "Maximum mount count:")
    # Partition nur pruefen, wenn beim naechsten mounten oder innerhalb
    # der nächsten 30 Stunden ohnehin ein fsck fällig wäre
    if [ $[${Mounts}+1] -lt ${MaxMounts} -o ${MaxMounts} -eq -1 ] && [ "$FSCK_FORCE" = "0" ] ; then
      echo "No need to check ${Drive}."
      continue
    fi
    echo "Checking ${Drive}"
    fsck -a -y -f ${Drive}
    retval=$?
    echo "fsck rc: $retval"
    if [ $retval eq 4 ] ; then
      echo "Checking again"
      fsck -a -y -f ${Drive}
      retval=$?
    fi
  # Partitionen, die nicht automatisch gemountet werden, ignorieren
  elif [ "${FsType}" = "xfs" -a "$FSCK_FORCE" = "0" ] ; then
    echo "Checking ${DRIVE}"
    fsck -a -y -f ${Drive}
    retval=$?
    echo "fsck rc: $retval"
    if [ $retval -gt 0 ] ; then
      echo "Checking again"
      xfs_repair ${DRIVE}
    fi
  elif [ "$FSCK_FORCE" != "0" ] ; then
    echo "Checking ${DRIVE}"
    fsck -a -y -f ${Drive}
    retval=$?
  fi
done < /etc/fstab
if [ "$ERROR" = "0" -a "$FSCK_FORCE" = "1" ] ; then
  mount -n -o remount,rw / > /dev/null
  rm -f /forcefsck
  mount -n -o remount,ro / > /dev/null
fi
