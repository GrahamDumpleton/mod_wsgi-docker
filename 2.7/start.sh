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

# Mark what runtime this is.

WHISKEY_RUNTIME=docker
export WHISKEY_RUNTIME

# Set up the home directory for the application.

WHISKEY_HOMEDIR=/app
export WHISKEY_HOMEDIR

# Set up the data directory for the application.

WHISKEY_DATADIR=/data
export WHISKEY_DATADIR

# Set up the system directory where we keep runtime files.

WHISKEY_TEMPDIR=/.whiskey
export WHISKEY_TEMPDIR

# Set up the user_vars directory where environment variable updates
# can be done.

WHISKEY_ENVDIR=/.whiskey/user_vars
export WHISKEY_ENVDIR

# Override the HOME directory for the user in case it isn't set to
# sensible value.

HOME=/var/www
export HOME

# Make sure we are in the correct working directory for the application.

cd $WHISKEY_HOMEDIR

# Override uid and gid lookup to cope with being randomly assigned IDs
# using the -u option to 'docker run'.

WHISKEY_USER_ID=$(id -u)
WHISKEY_GROUP_ID=$(id -g)

NSS_WRAPPER_PASSWD=$WHISKEY_TEMPDIR/passwd
export NSS_WRAPPER_PASSWD

cat /etc/passwd > $NSS_WRAPPER_PASSWD

if [ x"$WHISKEY_USER_ID" != x"0" ]; then 
    echo "www-user:x:$WHISKEY_USER_ID:$WHISKEY_GROUP_ID:www-user:/var/www:/sbin/nologin" >> $NSS_WRAPPER_PASSWD
else
    NSS_WRAPPER_PASSWD=/etc/passwd
fi

NSS_WRAPPER_GROUP=$WHISKEY_TEMPDIR/group
export NSS_WRAPPER_GROUP

cat /etc/group > $NSS_WRAPPER_GROUP

if [ x"$WHISKEY_GROUP_ID" != x"0" ]; then 
    echo "www-user:x:$WHISKEY_GROUP_ID:" >> $NSS_WRAPPER_GROUP
else
    NSS_WRAPPER_GROUP=/etc/group
fi

LD_PRELOAD=/usr/local/nss_wrapper/lib64/libnss_wrapper.so
export LD_PRELOAD

# Activate the Python virtual environment.

source $WHISKEY_TEMPDIR/virtualenv/bin/activate

# Copy environment variable configuration to the system directory used
# for runtime files. This is done so that the '.whiskey/deploy-env' can
# safely add or remove files without modifying the original source code
# directory. This is necessary as the original source code directory
# may not be writable, or could be a mounted directory and we do not
# want to modify any original outside of Docker.

mkdir -p $WHISKEY_ENVDIR

if [ -d .whiskey/user_vars ]; then
    cp .whiskey/user_vars/* $WHISKEY_ENVDIR/
fi

# Docker will have set any environment variables defined in the image or
# on the command line when the container has been run. Here we are going
# to look for any statically defined environment variables provided by
# the user as part of the actual application. These will have been
# placed in the '.whiskey/user_vars' directory. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to. Each of the
# environment variables is set and exported.

envvars=

for name in `ls $WHISKEY_ENVDIR`; do
    export $name=`cat $WHISKEY_ENVDIR/$name`
    envvars="$envvars $name"
done

# Run any user supplied script to be run to set, modify or delete the
# environment variables.

if [ -x .whiskey/action_hooks/deploy-env ]; then
    echo " -----> Running .whiskey/action_hooks/deploy-env"
    .whiskey/action_hooks/deploy-env
fi

# Go back and reset all the environment variables based on additions or
# changes. Unset any for which the environment variable file no longer
# exists, albeit in practice that is probably unlikely.

for name in `ls $WHISKEY_ENVDIR`; do
    export $name=`cat $WHISKEY_ENVDIR/$name`
done

for name in $envvars; do
    if test ! -f $WHISKEY_ENVDIR/$name; then
        unset $name
    fi
done

# Run any user supplied script to be run prior to starting the
# application in the actual container. The script must be executable in
# order to be run. It is not possible for this script to change the
# permissions so it is executable and then run it, due to some docker
# bug which results in the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

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

if test x"$MOD_WSGI_PROCESSES" != x""; then
    SERVER_ARGS="$SERVER_ARGS --processes $MOD_WSGI_PROCESSES"
fi

if test x"$MOD_WSGI_THREADS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --threads $MOD_WSGI_THREADS"
fi

if test x"$MOD_WSGI_MAX_CLIENTS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --max-clients $MOD_WSGI_MAX_CLIENTS"
fi

if test x"$MOD_WSGI_INITIAL_WORKERS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --initial-workers $MOD_WSGI_INITIAL_WORKERS"
fi

if test x"$MOD_WSGI_MINIMUM_SPARE_WORKERS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --minimum-spare-workers $MOD_WSGI_MINIMUM_SPARE_WORKERS"
fi

if test x"$MOD_WSGI_MAXIMUM_SPARE_WORKERS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --maximum-spare-workers $MOD_WSGI_MAXIMUM_SPARE_WORKERS"
fi

if test x"$MOD_WSGI_LIMIT_REQUEST_BODY" != x""; then
    SERVER_ARGS="$SERVER_ARGS --limit-request-body $MOD_WSGI_LIMIT_REQUEST_BODY"
fi

if test x"$MOD_WSGI_MAXIMUM_REQUESTS" != x""; then
    SERVER_ARGS="$SERVER_ARGS --maximum-requests $MOD_WSGI_MAXIMUM_REQUESTS"
fi

if test x"$MOD_WSGI_INACTIVITY_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --inactivity-timeout $MOD_WSGI_INACTIVITY_TIMEOUT"
fi

if test x"$MOD_WSGI_REQUEST_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --request-timeout $MOD_WSGI_REQUEST_TIMEOUT"
fi

if test x"$MOD_WSGI_CONNECT_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --connect-timeout $MOD_WSGI_CONNECT_TIMEOUT"
fi

if test x"$MOD_WSGI_SOCKET_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --socket-timeout $MOD_WSGI_SOCKET_TIMEOUT"
fi

if test x"$MOD_WSGI_QUEUE_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --queue-timeout $MOD_WSGI_QUEUE_TIMEOUT"
fi

if test x"$MOD_WSGI_HEADER_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --header-timeout $MOD_WSGI_HEADER_TIMEOUT"
fi

if test x"$MOD_WSGI_HEADER_MAX_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --header-max-timeout $MOD_WSGI_HEADER_MAX_TIMEOUT"
fi

if test x"$MOD_WSGI_HEADER_MIN_RATE" != x""; then
    SERVER_ARGS="$SERVER_ARGS --header-min-rate $MOD_WSGI_HEADER_MIN_RATE"
fi

if test x"$MOD_WSGI_BODY_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --body-timeout $MOD_WSGI_BODY_TIMEOUT"
fi

if test x"$MOD_WSGI_BODY_MAX_TIMEOUT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --body-max-timeout $MOD_WSGI_BODY_MAX_TIMEOUT"
fi

if test x"$MOD_WSGI_BODY_MIN_RATE" != x""; then
    SERVER_ARGS="$SERVER_ARGS --body-min-rate $MOD_WSGI_BODY_MIN_RATE"
fi

if test x"$MOD_WSGI_SERVER_BACKLOG" != x""; then
    SERVER_ARGS="$SERVER_ARGS --server-backlog $MOD_WSGI_SERVER_BACKLOG"
fi

if test x"$MOD_WSGI_DAEMON_BACKLOG" != x""; then
    SERVER_ARGS="$SERVER_ARGS --daemon-backlog $MOD_WSGI_DAEMON_BACKLOG"
fi

if test x"$MOD_WSGI_SERVER_MPM" != x""; then
    SERVER_ARGS="$SERVER_ARGS --server-mpm $MOD_WSGI_SERVER_MPM"
fi

if test x"$MOD_WSGI_LOG_LEVEL" != x""; then
    SERVER_ARGS="$SERVER_ARGS --log-level $MOD_WSGI_LOG_LEVEL"
fi

if test x"$MOD_WSGI_RELOAD_ON_CHANGES" != x""; then
    SERVER_ARGS="$SERVER_ARGS --reload-on-changes"
fi

if test x"$MOD_WSGI_ENABLE_DEBUGGER" != x""; then
    SERVER_ARGS="$SERVER_ARGS --debug-mode --enable-debugger"
fi

if test x"$NEW_RELIC_LICENSE_KEY" != x"" -o \
        x"$NEW_RELIC_CONFIG_FILE" != x""; then
    SERVER_ARGS="$SERVER_ARGS --with-newrelic"
fi

if test x"$MOD_WSGI_WORKING_DIRECTORY" != x""; then
    SERVER_ARGS="$SERVER_ARGS --working-directory $MOD_WSGI_WORKING_DIRECTORY"
fi

if test x"$MOD_WSGI_APPLICATION_TYPE" != x""; then
    SERVER_ARGS="$SERVER_ARGS --application-type $MOD_WSGI_APPLICATION_TYPE"
fi

if test x"$MOD_WSGI_ENTRY_POINT" != x""; then
    SERVER_ARGS="$SERVER_ARGS --entry-point $MOD_WSGI_ENTRY_POINT"
fi

if [ -f .whiskey/server_args ]; then
    SERVER_ARGS="$SERVER_ARGS `cat .whiskey/server_args`"
fi

if [ -x .whiskey/action_hooks/start ]; then
    echo " -----> Running .whiskey/action_hooks/start"
    exec .whiskey/action_hooks/start ${SERVER_ARGS} "$@"
else
    exec mod_wsgi-express start-server ${SERVER_ARGS} "$@"
fi
