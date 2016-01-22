#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# This script will execute the command passed as arguments.

# Setup the environment if not already done.

if [ x"$WHISKEY_PHASE" = x"" ]; then
    . `which mod_wsgi-docker-environ`
fi

# Finally set an environment variable as marker to indicate that the
# environment has been set up.

WHISKEY_PHASE=entrypoint
export WHISKEY_PHASE

# Now execute the command passed as arguments. If running as process ID
# 1, we want to do that as a sub process to the 'tini' process, which
# will perform reaping of zombie processes for us.

if [ $$ = 1 ]; then
    TINI="tini --"
fi

exec $TINI "$@"
