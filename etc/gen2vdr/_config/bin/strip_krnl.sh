#!/bin/sh

# this magic makes grep and co a lot faster
export LANG=C

kroot=
subarch=$(uname -i)
#subarch=x86
oldconfig=/proc/config.gz
localversion=
modulelist=
optimize_smp=
optimize_memory=
outputfile=

usage () {
    cat <<EOF
diet-kconfig -- Trim down kernel configs of unused modules
Usage: diet-kconfig [-options]
   Create a kernel config file based on the running system
option:
  -r ROOT  Specifies the linux-kernel root, default: current dir
  -a ARCH  Architecture (e.g. i386), default: running arch
  -c FILE  Old config file, default: /proc/config.gz)
  -o FILE  Output config file, default: kernel/.config
  -l LIST  Module list, default: read lsmod
  -v VER   Specifies the local version string, default: as is the original
  -s       Optimize SMP
  -m       Optimize memory model (for i386)
  -h       This help
EOF
    exit 1
}
while getopts r:a:c:o:l:v:pmh opt; do
    case "$opt" in
	r)
	    kroot="$OPTARG"
	    ;;
	a)
	    subarch="$OPTARG"
	    ;;
	c)
	    oldconfig="$OPTARG"
	    if [ ! -f "$oldconfig" ]; then
		echo "Cannot find old config $oldconfig"
		exit 1
	    fi
	    ;;
	o)
	    outputfile="$OPTARG"
	    ;;
	l)
	    modulelist="$OPTARG"
	    if [ ! -f "$modulelist" ]; then
		echo "Cannot find module list file modulelist"
		exit 1
	    fi
	    ;;
	v)
	    localversion="-$OPTARG"
	    ;;
	s)
	    optimize_smp=y
	    ;;
	m)
	    optimize_memory=y
	    ;;
	h)
	    usage
	    ;;
	*)
	    echo "Invalid option $opt"
	    usage
	    ;;
    esac
done

if [ -z "$kroot" ]; then
    kdir=.
else
    kdir="$kroot"
fi
if [ ! -d "$kdir" -o ! -f "$kdir"/Makefile -o ! -f "$kdir"/MAINTAINERS ]; then
    echo "Invalid kernel root directory $kdir"
    exit 1
fi

case $subarch in
    i?86|x86_64|GenuineIntel) arch=x86;;
    *) arch=$subarch;;
esac
tmpd=$(mktemp -q -d /tmp/dietkconf.XXXXXX)
cleanup () {
    rm -rf $tmpd
    exit 1
}
trap cleanup 0
curdir=$(pwd)

test -n "$kroot" && cd $kroot

# create a list of Makefile's
find arch/$arch block crypto drivers fs ipc kernel lib mm net security sound virt \
 -name 'Makefile' | xargs cat >> $tmpd/makefiles
# find configs to create the given module
find_kconfig () {
    module=$1
    modregex=$(echo $1 | sed -e's/_/[_-]/g')
    grep -E '^[[:space:]]*obj-\$\([A-Za-z0-9_]*\)[[:space:]]*[+:]=.*[[:space:]]'"$modregex"'\.o' $tmpd/makefiles | \
	sed -e's/^.*://g' -e's/^[[:space:]]*obj-\$(\(.*\)).*$/\1/g'
}
# set config no
kconfig_no () {
    sed -i -e's/^\('$1'\)=.*/# \1 is not set/' $tmpd/kconfig
}
# set config yes
kconfig_yes () {
    sed -i -e's/# '$1' .*/'$1'=y/' $tmpd/kconfig
}
# only previously selected modules with XXX marks
kconfig_mod () {
    sed -i -e's/# '$1' XXX/'$1'=m/' $tmpd/kconfig
}
get_old_config () {
    case "$oldconfig" in
	*.gz)
	    zcat $oldconfig
	    ;;
	*)
	    cat $oldconfig
    esac
}
list_modules () {
    if [ -n "$modulelist" ]; then
	awk '{if ($1 != "Module") {print $1}}' < $modulelist
    else
	lsmod | awk '{if ($1 != "Module") {print $1}}'
    fi
}
# copy the original kconfigs; reset all modules, but remember they were
# enabled by marking XXX
get_old_config | sed -e's/^\(CONFIG.*\)=m/# \1 XXX/g' > $tmpd/kconfig
# optimize some stuff (if given)
if [ "$optimize_smp" = "y" ]; then
    cpus=$(cat /proc/cpuinfo | grep -q -c 'processor[[:space:]]*:')
    if [ "$cpus" = 1 ]; then
	kconfig_no CONFIG_SMP
    else
	kconfig_yes CONFIG_SMP
    fi
fi
if [ "$subarch" = "i386" ]; then
    if [ "$optimize_memory" = "y" ]; then
 	mem=$(free | grep 'Mem:' | awk '{print $2}')
	if [ $mem -gt 4194304 ]; then
	    kconfig_yes CONFIG_HIGHMEM64G
	    kconfig_no CONFIG_HIGHMEM4G
	    kconfig_no CONFIG_NOHIGHMEM
	    kconfig_yes CONFIG_X86_PAE
	elif [ $mem -gt 1048576 ]; then
	    kconfig_no CONFIG_HIGHMEM64G
	    kconfig_yes CONFIG_HIGHMEM4G
	    kconfig_no CONFIG_NOHIGHMEM
	    kconfig_no CONFIG_X86_PAE
	else
	    kconfig_no CONFIG_HIGHMEM64G
	    kconfig_no CONFIG_HIGHMEM4G
	    kconfig_yes CONFIG_NOHIGHMEM
	    kconfig_no CONFIG_X86_PAE
	fi
    fi
fi
# rewrite the local version
if [ -n "$localversion" ]; then
    sed -i -e's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="'$localversion'"/' $tmpd/kconfig
fi

# find kconfig for each module
rm -f $noconfigs $okconfigs
list_modules | while read m; do
    echo -n "Checking module $m..."
    cfgs=$(find_kconfig $m)
    if [ -z "$cfgs" ]; then
	echo -n "N/A"
	echo $m >> $tmpd/conf-no
    else
	echo -n "$m" >> $tmpd/conf-ok
	for c in $cfgs; do
	    echo -n " $c"
	    echo -n " $c" >> $tmpd/conf-ok
	    kconfig_mod $c
	done
	echo >> $tmpd/conf-ok
    fi
    echo
done
# if the previously =m doesn't enable any modules, it's a virtual one, which
# we should keep =m
for c in $(grep '^#.*XXX$' $tmpd/kconfig | sed -e's/^#.*\(CONFIG.*\) XXX/\1/g'); do
    grep -q 'obj-\$('$c').*=.*\.o' $tmpd/makefiles || kconfig_mod $c
done
# replace XXX to standard
sed -i -e's/^\(#.*\) XXX/\1 is not set/g' $tmpd/kconfig

# reconfigure
echo "Reconfiguring via make silentconfig"
cd $curdir
cp $tmpd/kconfig .config

if [ -n "$kroot" ]; then
    make_args="-C $kroot O=$curdir"
else
    make_args=
fi
make $make_args silentoldconfig ARCH=$arch

if [ -n "$outputfile" ]; then
    echo "Copying the result to $outputfile"
    cp .config $outputfile
fi

echo
echo "*** FINISHED ***"
echo
if [ -s $tmpd/conf-no ]; then
    echo "Modules not configured:"
    cat $tmpd/conf-no
fi

if [ -s $tmpd/conf-ok ]; then
    while read m cfgs; do
	found=
	for c in $cfgs; do
	    if grep -q $c=m .config; then
		found=y
		break
	    fi
	done
	if [ -z "$found" ]; then
	    echo "Not enabled: module $m with config $cfgs"
	fi
    done < $tmpd/conf-ok
fi

exit 0
