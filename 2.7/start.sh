#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# This script will run 'mod_wsgi-express start-server', adding in some
# additional initial arguments to send logging to the terminal and to
# force the use of port 80. If necessary the port to use can be overridden
# using the PORT environment variable.

# Setup the environment if not already done.

if [ x"$WHISKEY_PHASE" = x"" ]; then
    . `which mod_wsgi-docker-environ`
fi

# Run any user supplied script to be run prior to starting the
# application in the actual container. The script must be executable in
# order to be run. It is not possible for this script to change the
# permissions so it is executable and then run it, due to some docker
# bug which results in the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -f .whiskey/action_hooks/deploy ]; then
    if [ ! -x .whiskey/action_hooks/deploy ]; then
        echo "WARNING: Script .whiskey/action_hooks/deploy not executable."
    fi
fi

if [ -x .whiskey/action_hooks/deploy ]; then
    echo " -----> Running .whiskey/action_hooks/deploy"
    .whiskey/action_hooks/deploy
fi

# Now run the the actual application under Apache/mod_wsgi. This is run
# in the foreground, replacing this process and adopting process ID 1 so
# that signals are received properly and Apache will shutdown properly
# when the container is being stopped. It will log to stdout/stderr.
#
# In running the mod_wsgi-express command, we collect select override
# arguments from the environment. We also allow extra server arguments
# in the file '.whiskey/server_args', plus allow the whole command to be
# overridden using '.whiskey/action_hooks/start'.

SERVER_ARGS="--log-to-terminal --startup-log --port 80"

if [ x"$MOD_WSGI_PROCESSES" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --processes $MOD_WSGI_PROCESSES"
fi

if [ x"$MOD_WSGI_THREADS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --threads $MOD_WSGI_THREADS"
fi

if [ x"$MOD_WSGI_MAX_CLIENTS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --max-clients $MOD_WSGI_MAX_CLIENTS"
fi

if [ x"$MOD_WSGI_INITIAL_WORKERS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --initial-workers $MOD_WSGI_INITIAL_WORKERS"
fi

if [ x"$MOD_WSGI_MINIMUM_SPARE_WORKERS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --minimum-spare-workers $MOD_WSGI_MINIMUM_SPARE_WORKERS"
fi

if [ x"$MOD_WSGI_MAXIMUM_SPARE_WORKERS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --maximum-spare-workers $MOD_WSGI_MAXIMUM_SPARE_WORKERS"
fi

if [ x"$MOD_WSGI_LIMIT_REQUEST_BODY" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --limit-request-body $MOD_WSGI_LIMIT_REQUEST_BODY"
fi

if [ x"$MOD_WSGI_MAXIMUM_REQUESTS" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --maximum-requests $MOD_WSGI_MAXIMUM_REQUESTS"
fi

if [ x"$MOD_WSGI_INACTIVITY_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --inactivity-timeout $MOD_WSGI_INACTIVITY_TIMEOUT"
fi

if [ x"$MOD_WSGI_REQUEST_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --request-timeout $MOD_WSGI_REQUEST_TIMEOUT"
fi

if [ x"$MOD_WSGI_CONNECT_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --connect-timeout $MOD_WSGI_CONNECT_TIMEOUT"
fi

if [ x"$MOD_WSGI_SOCKET_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --socket-timeout $MOD_WSGI_SOCKET_TIMEOUT"
fi

if [ x"$MOD_WSGI_QUEUE_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --queue-timeout $MOD_WSGI_QUEUE_TIMEOUT"
fi

if [ x"$MOD_WSGI_HEADER_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --header-timeout $MOD_WSGI_HEADER_TIMEOUT"
fi

if [ x"$MOD_WSGI_HEADER_MAX_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --header-max-timeout $MOD_WSGI_HEADER_MAX_TIMEOUT"
fi

if [ x"$MOD_WSGI_HEADER_MIN_RATE" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --header-min-rate $MOD_WSGI_HEADER_MIN_RATE"
fi

if [ x"$MOD_WSGI_BODY_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --body-timeout $MOD_WSGI_BODY_TIMEOUT"
fi

if [ x"$MOD_WSGI_BODY_MAX_TIMEOUT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --body-max-timeout $MOD_WSGI_BODY_MAX_TIMEOUT"
fi

if [ x"$MOD_WSGI_BODY_MIN_RATE" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --body-min-rate $MOD_WSGI_BODY_MIN_RATE"
fi

if [ x"$MOD_WSGI_SERVER_BACKLOG" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --server-backlog $MOD_WSGI_SERVER_BACKLOG"
fi

if [ x"$MOD_WSGI_DAEMON_BACKLOG" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --daemon-backlog $MOD_WSGI_DAEMON_BACKLOG"
fi

if [ x"$MOD_WSGI_SERVER_MPM" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --server-mpm $MOD_WSGI_SERVER_MPM"
fi

if [ x"$MOD_WSGI_LOG_LEVEL" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --log-level $MOD_WSGI_LOG_LEVEL"
fi

if [ x"$MOD_WSGI_RELOAD_ON_CHANGES" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --reload-on-changes"
fi

if [ x"$MOD_WSGI_ENABLE_DEBUGGER" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --debug-mode --enable-debugger"
fi

if [ x"$MOD_WSGI_WORKING_DIRECTORY" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --working-directory $MOD_WSGI_WORKING_DIRECTORY"
fi

if [ x"$MOD_WSGI_APPLICATION_TYPE" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --application-type $MOD_WSGI_APPLICATION_TYPE"
fi

if [ x"$MOD_WSGI_ENTRY_POINT" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --entry-point $MOD_WSGI_ENTRY_POINT"
fi

if [ x"$NEW_RELIC_LICENSE_KEY" != x"" -o \
        x"$NEW_RELIC_CONFIG_FILE" != x"" ]; then
    SERVER_ARGS="$SERVER_ARGS --with-newrelic"
fi

if [ -f .whiskey/server_args ]; then
    SERVER_ARGS="$SERVER_ARGS `cat .whiskey/server_args`"

    # Expand any environment variable references in options.

    TMPFILE=/tmp/server_args.$$

    cat > $TMPFILE << EOF
#!/bin/sh
cat << !
$SERVER_ARGS
!
EOF

    chmod +x $TMPFILE

    SERVER_ARGS=`$TMPFILE`

    rm -f $TMPFILE
fi

if [ $$ = 1 ]; then
    TINI="tini --"
fi

if [ -f .whiskey/action_hooks/start ]; then
    if [ ! -x .whiskey/action_hooks/start ]; then
        echo "WARNING: Script .whiskey/action_hooks/start not executable."
    fi
fi

if [ -x .whiskey/action_hooks/start ]; then
    echo " -----> Running .whiskey/action_hooks/start"
    exec $TINI .whiskey/action_hooks/start ${SERVER_ARGS} "$@"
fi

if [ -f /home/whiskey/action_hooks/start ]; then
    if [ ! -x /home/whiskey/action_hooks/start ]; then
        echo "WARNING: Script /home/whiskey/action_hooks/start not executable."
    fi
fi

if [ -x /home/whiskey/action_hooks/start ]; then
    echo " -----> Running /home/whiskey/action_hooks/start"
    exec $TINI /home/whiskey/action_hooks/start ${SERVER_ARGS} "$@"
fi

exec $TINI mod_wsgi-express start-server ${SERVER_ARGS} "$@"
