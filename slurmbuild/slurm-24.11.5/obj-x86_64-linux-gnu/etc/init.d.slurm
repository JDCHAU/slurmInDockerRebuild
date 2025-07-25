#!/bin/bash
#
# chkconfig: 345 90 10
# description: SLURM is a simple resource management system which \
#              manages exclusive access to a set of compute \
#              resources and distributes work to those resources.
#
# processname: /usr/sbin/slurmd
# pidfile: /var/run/slurmd.pid
#
# processname: /usr/sbin/slurmctld
# pidfile: /var/run/slurmctld.pid
#
# config: /etc/sysconfig/slurm
#
### BEGIN INIT INFO
# Provides:          slurm
# Required-Start:    $remote_fs $syslog $network munge
# Required-Stop:     $remote_fs $syslog $network munge
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: slurm daemon management
# Description:       Start slurm to provide resource management
### END INIT INFO

BINDIR="/usr/bin"
CONFDIR="/etc/slurm"
LIBDIR="/usr/lib/x86_64-linux-gnu"
SBINDIR="/usr/sbin"

# Source function library.
if [ -f /etc/rc.status ]; then
   . /etc/rc.status
   SUSE=1
   STARTPROC=startproc

   rc_reset
else
   if [ ! -f /etc/rc.d/init.d/functions ]; then
      echo "Could not find /etc/rc.d/init.d/functions. Is some other daemon launch mechanism used?"
      exit 1
   fi
   . /etc/rc.d/init.d/functions
   SUSE=0
   STARTPROC=daemon

   function rc_status() {
      RETVAL=$?
   }
   function rc_exit () {
      exit $RETVAL
   }
   RETVAL=0
fi

# We can not use a starter program without losing environment
# variables that are critical on Blue Gene systems
if [ -d /bgl/BlueLight/ppcfloor ]; then
   STARTPROC=""
fi

# Source slurm specific configuration
# This can be used to alter limits for users jobs or set daemon options.
# For example, the limits for user jobs could be higher or lower than the
# default limits for user root (e.g. "ulimit -t unlimited" sets an unlimited
# CPU time limit for spawned user jobs).
# SLURMCTLD_OPTIONS defines slurmctld command line options. See "man slurmctld"
# SLURMD_OPTIONS defines slurmd command line options. See "man slurmd"
if [ -f /etc/sysconfig/slurm ] ; then
    . /etc/sysconfig/slurm
else
    SLURMCTLD_OPTIONS=""
    SLURMD_OPTIONS=""
fi

if [ ! -x $BINDIR/scontrol ]; then
   echo "Could not find $BINDIR/scontrol. Bad path?"
   exit 1
fi

if [ ! -f $CONFDIR/slurm.conf ]; then
   echo "Could not find $CONFDIR/slurm.conf. Bad path?"
   exit 1
fi

# setup library paths for slurm and munge support
export LD_LIBRARY_PATH=$LIBDIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

start() {
    prog=$1
    shift
    echo -n "starting $prog: "
    unset HOME MAIL USER USERNAME

    $STARTPROC $SBINDIR/$prog $*
    rc_status -v
    echo
    touch /var/lock/subsys/slurm
}

stop() {
    echo -n "stopping $1: "
    killproc $1 -TERM
    rc_status -v
    echo
    rm -f /var/lock/subsys/slurm
}

startall() {
    for prog in `$BINDIR/scontrol show daemons`; do
	optvar=`echo ${prog}_OPTIONS | tr "a-z" "A-Z"`
	if [[ ${MULTIPLE_SLURMD} == yes ]] && [[ ${prog} == slurmd ]]
	then
	    for node in $($BINDIR/scontrol show aliases)
	    do
		start $prog -N ${node} ${!optvar}
	    done
	else
	    start $prog ${!optvar}
	fi
    done
}

#
# status() with slight modifications to take into account
# instantiations of job manager slurmd's, which should not be
# counted as "running"
#
slurmstatus() {
    local base=${1##*/}
    local pid
    local rpid
    local pidfile
    local pidfiles
    local rc

    pidfile=`grep -i ${base}pid $CONFDIR/slurm.conf | grep -v '^ *#'`
    if [ $? = 0 ]; then
	pidfile=${pidfile##*=}
	pidfile=${pidfile%#*}
	pidfile=${pidfile//\"/}
    else
	pidfile=/var/run/${base}.pid
    fi

    pid=`pidof -o $$ -o $$PPID -o %PPID -x $1 || \
	 pidof -o $$ -o $$PPID -o %PPID -x ${base}`

    if [ "$base" == "slurmd" ] ; then
	echo ${pidfile} | grep -q %n
	if [[ $? -eq 0 ]]
	then
	    for n in $($BINDIR/scontrol show aliases)
	    do
		pidfiles="${pidfiles} $(echo ${pidfile} | sed "s/%n/$n/g")"
	    done
	else
	    pidfiles=${pidfile}
	fi
    else
	pidfiles=${pidfile}
    fi

    RETVAL=0
    for pidfile in ${pidfiles}
    do
	rc=1
	if [ -f $pidfile ]; then
	    read rpid < $pidfile
	    if [ "$rpid" != "" -a "$pid" != "" ]; then
		for i in $pid ; do
		    if [ "$i" = "$rpid" ]; then
			echo $"${base} (pid $rpid) is running..."
			rc=0
			break
		    fi
		done
	    elif [ "$rpid" != "" -a "$pid" = "" ]; then
#           Due to change in user id, pid file may persist
#           after slurmctld terminates
		if [ "$base" != "slurmctld" ] ; then
		    echo $"${base} dead but pid file exists"
		else
		    echo $"${base} is stopped"
		fi
		RETVAL=1
	    fi
	fi

	if [[ $rc -eq 0 ]]
	then
	    continue
	fi

	if [ "$base" = "slurmctld" -a "$pid" != "" ] ; then
	    echo $"${base} (pid $pid) is running..."
	    continue
	fi

	echo $"${base} is stopped"
	if [ "$RETVAL" == "0" ]; then
	    RETVAL=3
	fi
    done

    return $RETVAL
}

#
# stop slurm daemons,
# wait for termination to complete (up to 10 seconds) before returning
#
slurmstop() {
    for prog in `$BINDIR/scontrol show daemons`; do
       stop $prog

       for i in 1 2 3 4
       do
	  sleep $i
	  slurmstatus $prog
	  if [ $? != 0 ]; then
	     break
	  fi
       done
    done

    # slurmstatus return 1 or 3 in case of stopped daemon
    # and that is what we are looking for here
    if [[ ${RETVAL} =~ 1|3 ]]
    then
        RETVAL=0
    else
        RETVAL=1
    fi
}

#
# The pathname substitution in daemon command assumes prefix and
# exec_prefix are same.  This is the default, unless the user requests
# otherwise.
#
# Any node can be a slurm controller and/or server.
#
case "$1" in
    start)
	startall
	;;
    startclean)
	SLURMCTLD_OPTIONS="-c $SLURMCTLD_OPTIONS"
	SLURMD_OPTIONS="-c $SLURMD_OPTIONS"
	startall
	;;
    stop)
	slurmstop
	;;
    status)
	anystop=0
	for prog in `$BINDIR/scontrol show daemons`; do
	   slurmstatus $prog
	   rc=$?
	   if [ $rc != 0 ] ; then
	       anystop=$rc
	   fi
	done
	RETVAL=$anystop
	;;
    restart)
	$0 stop
	$0 start
	;;
    condrestart)
	if [ -f /var/lock/subsys/slurm ]; then
	    for prog in `$BINDIR/scontrol show daemons`; do
		 stop $prog
		 sleep 1
		 optvar=`echo ${prog}_OPTIONS | tr "a-z" "A-Z"`
		 if [[ ${MULTIPLE_SLURMD} == yes ]] && [[ ${prog} == slurmd ]]
		 then
		     for node in $($BINDIR/scontrol show aliases)
		     do
			 start $prog -N ${node}
		     done
		 else
		     start $prog ${!optvar}
		 fi
	    done
	fi
	;;
    reconfig|reload)
	for prog in `$BINDIR/scontrol show daemons`; do
	    echo -n $"Reloading $prog daemon configuration: "
	    killproc $prog -HUP
	    echo
	done
	;;
    test)
	for prog in `$BINDIR/scontrol show daemons`; do
	    echo "$prog runs here"
	done
	;;
    *)
	echo "Usage: $0 {start|startclean|stop|status|restart|reconfig|condrestart|test}"
	exit 1
	;;
esac

rc_exit
