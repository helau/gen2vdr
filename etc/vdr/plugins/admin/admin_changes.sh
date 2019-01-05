#!/bin/bash
source /etc/vdr.d/conf/gen2vdr.cfg

CFG_LAST="$ADMIN_CFG_FILE.last"

${ADMIN_SCRIPT_PATH}/setvdrconf.sh

rm -rf $ADMIN_EXEC_SCRIPT > /dev/null 2>&1

if [ -s $CFG_LAST ] && [ "$1" != "-f" ] ; then
   [ "$(diff -uN $ADMIN_CFG_FILE $CFG_LAST)" = "" ] && exit 0
   ALL_SCRIPTS=$(diff $ADMIN_CFG_FILE $CFG_LAST | grep "^< /" | grep -v "setvdrconf\.sh" | cut -b 3- | cut -d ":" -f 1 | sort -u)
else
   ALL_SCRIPTS=$(cat $ADMIN_CFG_FILE | grep "^/" | grep -v "setvdrconf\.sh" | cut -d ":" -f 1 | sort -u)
fi
echo "#!/bin/bash" > $ADMIN_EXEC_SCRIPT

LAST_SCRIPT=""
echo "sh ${ADMIN_SCRIPT_PATH}/cfgplg.sh 2>&1 >> ${ADMIN_LOG_FILE}" >> $ADMIN_EXEC_SCRIPT

for i in $ALL_SCRIPTS ; do
   if [ -f ${i} ] ; then
      echo "${i} 2>&1 >> $ADMIN_LOG_FILE" >> $ADMIN_EXEC_SCRIPT
   else
      echo "#<${i}> not found" >> $ADMIN_EXEC_SCRIPT
      echo "<${i}> not found"
   fi
done
echo "cp -f $ADMIN_CFG_FILE $CFG_LAST" >> $ADMIN_EXEC_SCRIPT
chmod +x $ADMIN_EXEC_SCRIPT
if [ "$1" = "-f" ] ; then
   set -x
   . $ADMIN_EXEC_SCRIPT
   set +x
   rm -f $ADMIN_EXEC_SCRIPT
fi
