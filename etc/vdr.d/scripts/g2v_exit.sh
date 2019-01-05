#!/bin/bash
source /etc/vdr.d/conf/gen2vdr.cfg
#if [ -f $ADMIN_EXEC_SCRIPT ] ; then
#   sh $ADMIN_EXEC_SCRIPT
#   rm -rf $ADMIN_EXEC_SCRIPT
#fi
/_config/bin/g2v_updadminconf.sh -c	
sh /_config/bin/setscart.sh TVOUT &
