#!/bin/bash
source /_config/bin/g2v_funcs.sh
MOD_CONF=/etc/conf.d/modules
#set -x

function usage
{
   echo "Syntax:"
   echo "   module-update.sh <action> <module> [parms]"
   echo "       action must be add or del or args."
   echo "       parms are module parms for action args or can be 'first' for action add."
   echo ""
   exit 1
}

[ "$2" = "" ] && usage
action="$1"
[ "$action" != "del" ] && [ "$(modinfo $2)" = "" ] && usage
module="${2//-/_}"
shift;shift
[ ! -e "$MOD_CONF" ] && touch "$MOD_CONF"
source $MOD_CONF

act_mods=" ${modules//-/_} "
new_mods="$act_mods"
if [ "$action" = "add" ] ; then
   if [ "${act_mods/* $module */}" != "" ] ; then
      if [ "$1" = "first" ] ; then
         new_mods="$module $modules"
      else
         new_mods="$modules $module"
      fi
   else
      echo "Module <$module> is already in autoload sequence"
      exit 0
   fi
elif [ "$action" = "del" ] ; then
   if [ "${act_mods/* $module */}" = "" ] ; then
      new_mods="${act_mods/ $module / }"
   else
      echo "Module <$module> is not in autoload sequence"
      exit 1
   fi
elif [ "$action" = "args" ] ; then
   args="$@"
   if [ "$args" != "" ] ; then
      glogger -s "Setting module args: <$module> <$args>"
      if [ "$(grep "^module_${module}_args" $MOD_CONF)" != "" ] ; then
         sed -i $MOD_CONF -e "s/^module_${module}_args.*/module_${module}_args=\"$args\"/"
      else
         echo "module_${module}_args=\"$args\"" >> $MOD_CONF
      fi
      if [ "$(grep "^options ${module} " /etc/modprobe.d/g2v.conf)" != "" ] ; then
         sed -i /etc/modprobe.d/g2v.conf -e "s/^options ${module} .*/options ${module} $args/"
      else
         echo "options ${module} $args" >> /etc/modprobe.d/g2v.conf
      fi
   else
      sed -i $MOD_CONF -e "/^module_${module}_args.*/d"
      sed -i /etc/modprobe.d/g2v.conf -e "/^options ${module} .*/d"
   fi
#   update-modules
else
   usage
fi

if [ "$new_mods" != "$act_mods" ] ; then
   new_mods="${new_mods# }"
   new_mods="${new_mods% }"
   glogger -s "Setting modules: <$new_mods>"
   if [ "$(grep "^modules=" $MOD_CONF)" != "" ] ; then
      sed -i $MOD_CONF -e "s/^modules=.*/modules=\"$new_mods\"/"
   else
      echo "modules=\"$new_mods\"" >> $MOD_CONF
   fi
fi
