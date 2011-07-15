#!/bin/sh
### BEGIN INIT INFO
# Provides:          haproxy
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: fast and reliable load balancing reverse proxy
# Description:       This file should be used to start and stop haproxy.
### END INIT INFO

# Author: Arnaud Cornet <acornet@debian.org>

PATH=/sbin:/usr/sbin:/bin:/usr/bin
PIDFILE=/var/run/haproxy.pid
HAPROXY=/usr/local/sbin/haproxy
CONFIG=/etc/haproxy.cfg
EXTRAOPTS=
ENABLED=1

test -x $HAPROXY || exit 0
test -f "$CONFIG" || exit 0

if [ -e /etc/default/haproxy ]; then
	. /etc/default/haproxy
fi

test "$ENABLED" != "0" || exit 0

[ -f /etc/default/rcS ] && . /etc/default/rcS
. /lib/lsb/init-functions


haproxy_start()
{
	start-stop-daemon --start --pidfile "$PIDFILE" \
		--exec $HAPROXY -- -f "$CONFIG" -D -p "$PIDFILE" \
		$EXTRAOPTS || return 2
	return 0
}

haproxy_stop()
{
	start-stop-daemon --stop --user root --pidfile "$PIDFILE" \
		|| return 2
	return 0
}

haproxy_reload()
{

        # haproxy -f /etc/haproxy.conf -sf `cat /var/run/haproxy.pid`
 	$HAPROXY -f "$CONFIG" -sf `cat $PIDFILE` || return 2
	return 0
}

case "$1" in
start)
	log_daemon_msg "Starting haproxy" "haproxy"
	haproxy_start
	case "$?" in
	0)
		log_end_msg 0
		;;
	1)
		log_end_msg 1
		echo "pid file '$PIDFILE' found, haproxy not started."
		;;
	2)
		log_end_msg 1
		;;
	esac
	;;
stop)
	log_daemon_msg "Stopping haproxy" "haproxy"
	haproxy_stop
	case "$?" in
	0|1)
		log_end_msg 0
		;;
	2)
		log_end_msg 1
		;;
	esac
	;;
reload|force-reload)
	log_daemon_msg "Reloading haproxy" "haproxy"
	haproxy_reload
	case "$?" in
	0|1)
		log_end_msg 0
		;;
	2)
		log_end_msg 1
		;;
	esac
	;;
restart)
	log_daemon_msg "Restarting haproxy" "haproxy"
	haproxy_stop
	haproxy_start
	case "$?" in
	0)
		log_end_msg 0
		;;
	1)
		log_end_msg 1
		;;
	2)
		log_end_msg 1
		;;
	esac
	;;
*)
	echo "Usage: /etc/init.d/haproxy {start|stop|reload|restart}"
	exit 3
	;;
esac

:
