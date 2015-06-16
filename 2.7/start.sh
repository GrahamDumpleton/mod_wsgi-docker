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

# Set up the system and bin directory where our scripts will be.

WHISKEY_SYSDIR=/.whiskey
export WHISKEY_SYSDIR

WHISKEY_BINDIR=$WHISKEY_SYSDIR/python/bin
export WHISKEY_BINDIR

# Set up the user_vars directory where environment variable updates
# can be done.
#
# Note that every instance of a container will have their own copy of
# the filesystem so we do not have to worry about them interfering with
# each other. We can therefore use the user_vars directory as the
# environment directory.

WHISKEY_ENVDIR=/app/.whiskey/user_vars
export WHISKEY_ENVDIR

# Make sure we are in the correct working directory for the application.

cd $WHISKEY_HOMEDIR

# Docker will have set any environment variables defined in the image or
# on the command line when the container has been run. Here we are going
# to look for any statically defined environment variables provided by
# the user as part of the actual application. These will have been
# placed in the '.whiskey/user_vars' directory. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to. Each of the
# environment variables is set and exported.

envvars=

if [ -d .whiskey/user_vars ]; then
    for name in `ls .whiskey/user_vars`; do
        export $name=`cat .whiskey/user_vars/$name`
        envvars="$envvars $name"
    done
fi

# Run any user supplied script to be run to set, modify or delete the
# environment variables.

if [ -x .whiskey/action_hooks/deploy-env ]; then
    echo " -----> Running .whiskey/action_hooks/deploy-env"
    .whiskey/action_hooks/deploy-env
fi

# Go back and reset all the environment variables based on additions or
# changes. Unset any for which the environment variable file no longer
# exists, albeit in practice that is probably unlikely.

if [ -d .whiskey/user_vars ]; then
    for name in `ls .whiskey/user_vars`; do
        export $name=`cat .whiskey/user_vars/$name`
    done

    for name in $envvars; do
        if test ! -f .whiskey/user_vars/$name; then
            unset $name
        fi
    done
fi

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

SERVER_ARGS="--log-to-terminal --startup-log --port 80"

if test x"$NEW_RELIC_LICENSE_KEY" != x"" -o \
        x"$NEW_RELIC_CONFIG_FILE" != x""; then
    SERVER_ARGS="$SERVER_ARGS --with-newrelic"
fi

exec mod_wsgi-express start-server ${SERVER_ARGS} "$@"
