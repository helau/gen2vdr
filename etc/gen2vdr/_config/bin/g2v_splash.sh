# Gen2VDR splash functions - adopted from /sbin/splash-functions.sh
source /_config/bin/g2v_funcs.sh
source /etc/conf.d/splash

spl_daemon="/sbin/fbsplashd.static"
spl_fbcd="/sbin/fbcondecor_ctl"
spl_cachedir="/lib/splash/cache"
spl_fifo="${spl_cachedir}/.splash"

g2v_splash_start() {
        g2v_splash_exit
	# Prepare the communications FIFO
	mkfifo ${spl_fifo}

	local options=""
	[[ ${SPLASH_KDMODE} == "GRAPHICS" ]] && options="--kdgraphics"
	[[ -n ${SPLASH_EFFECTS} ]] && options="${options} --effects=${SPLASH_EFFECTS}"
	[[ ${SPLASH_THEME} == "" ]] && SPLASH_THEME="g2v"

	if [ "$1" == "bootup" ]; then
		BMSG="${SPLASH_BOOT_MESSAGE}"
	else
		BMSG="${SPLASH_SHUTDOWN_MESSAGE}"
	fi
		
	# Start the splash daemon	
	glogger -s "Starting splash - $BMSG ${spl_daemon} --theme=${SPLASH_THEME} --type=$1 ${options}"
	BOOT_MSG="$BMSG" ${spl_daemon} --theme=${SPLASH_THEME} --type=$1 ${options}

	# Set the silent TTY and boot message
	splash_comm_send "set tty silent 16"
	splash_comm_send "set mode silent"
	splash_comm_send "repaint"
	${spl_fbcd} -c on 2>/dev/null

	# Set the input device if it exists. This will make it possible to use F2 to
	# switch from verbose to silent.
	local t=$(grep -Hsi keyboard /sys/class/input/input*/name | sed -e 's#.*input\([0-9]*\)/name.*#event\1#')
	if [[ -z "${t}" ]]; then
		t=$(grep -Hsi keyboard /sys/class/input/event*/device/driver/description | grep -o 'event[0-9]\+')
		if [[ -z "${t}" ]]; then
			# Try an alternative method of finding the event device. The idea comes
			# from Bombadil <bombadil(at)h3c.de>. We're couting on the keyboard controller
			# being the first device handled by kbd listed in input/devices.
			t=$(/bin/grep -s -m 1 '^H: Handlers=kbd' /proc/bus/input/devices | grep -o 'event[0-9]*')
		fi
	fi
	[[ -n "${t}" ]] && splash_comm_send "set event dev /dev/input/${t}"

	return 0
}

g2v_splash_exit() {
	# If we're in sysinit or rebooting, do nothing.
	rm -f ${spl_fifo} 2>/dev/null

	# In the unlikely case that there's a splash daemon running -- kill it.
	killall -9 ${spl_daemon##*/} 2>/dev/null
}


g2v_splash_prog() {
	progress=$(($1 * 65535 / $2))
	splash_comm_send "progress ${progress}"
	splash_comm_send "paint"
}
	    


###########################################################################
# Common functions
###########################################################################
splash_comm_send() {        
        [ "$(pidof $(basename ${spl_daemon}))" = "" ] && return 1
		
	echo "$*" > ${spl_fifo} &
}

