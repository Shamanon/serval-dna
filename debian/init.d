#!/bin/sh
### BEGIN INIT INFO
# Provides:          serval-dna
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Serval DNA daemon
# Description:       Daemon for providing Serval Mesh network services
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

SCRIPTNAME=serval-dna
DEFAULTFILE=/etc/default/$SCRIPTNAME
SCRIPTPATH=/etc/init.d/$SCRIPTNAME

DESC="Serval DNA daemon"
USER=serval
DAEMON=/usr/sbin/servald
SERVALINSTANCE_PATH=/var/serval-node
START_DAEMON=yes

. /lib/lsb/init-functions

test -f "$DEFAULTFILE" && . "$DEFAULTFILE"

test -x "$DAEMON" || exit 0

NAME="${DAEMON##*/}"

if [ -z "$CONFFILE" ]; then
    CONFFILE="$SERVALINSTANCE_PATH/serval.conf"
fi
if [ -z "$PIDFILE" ]; then
    PIDFILE="${SERVALINSTANCE_PATH:-/var/serval-node}/servald.pid"
fi

if [ ! "$START_DAEMON" = "yes" -a "$1" = "start" ]; then
    log_warning_msg "Not starting $DESC, disabled via $DEFAULTFILE"
    exit 0
fi

if [ ! -e "$CONFFILE" ]; then
    log_failure_msg "Cannot start $DESC, $CONFFILE not found"
    exit 6
fi

if ! id $USER >/dev/null 2>&1; then
    log_failure_msg "Cannot start $DESC, user '$USER' does not exist"
    exit 1
fi

export SERVALINSTANCE_PATH

daemon_start() {
    start-stop-daemon --chuid $USER --exec "$DAEMON" --user $USER --name $NAME --pidfile "$PIDFILE" --start -- start >/dev/null
}

daemon_stop() {
   "$DAEMON" stop >/dev/null
    #start-stop-daemon --chuid $USER --exec "$DAEMON" --user $USER --name $NAME --pidfile "$PIDFILE" --signal TERM --retry 2 --stop -- stop
}

daemon_status() {
    "$DAEMON" status | grep -q '^status:running$'
}

case "$1" in
start)
    log_daemon_msg "Starting $DESC" "$NAME"
    if daemon_status; then
        log_progress_msg "(already running)"
        log_end_msg 0
    elif daemon_start; then
        log_end_msg 0
    else
        log_end_msg 1
        exit 1
    fi
    ;;

status)
    if daemon_status; then
        log_success_msg "$NAME is running"
    else
        log_failure_msg "$NAME is not running"
    fi
    ;;

stop)
    log_daemon_msg "Stopping $DESC" "$NAME"
    if daemon_stop; then
        log_end_msg 0
    else
        log_progress_msg "(not running)"
        log_end_msg 1
        exit 1
    fi
    ;;

force-reload|restart)
    log_daemon_msg "Restarting $DESC" "$NAME"
    if ! daemon_stop; then
        log_end_msg 1
        exit 1
    fi
    sleep 1
    if daemon_start; then
        log_end_msg 0
    else
        log_end_msg 1
        exit 1
    fi
    ;;

*)
    log_warning_msg "Usage: $SCRIPTPATH {start|stop|restart|force-reload}"
    log_warning_msg "  start - starts system-wide $DESC"
    log_warning_msg "  stop  - stops system-wide $DESC"
    log_warning_msg "  restart, force-reload - starts a new system-wide $DESC"
    exit 1
    ;;
esac

exit 0

# vim:sw=8:sts=4:sw=4:
