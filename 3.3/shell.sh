#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# This script will run an interactive bash shell.

# Setup the environment if not already done.

if [ x"$WHISKEY_PHASE" = x"" ]; then
    . `which mod_wsgi-docker-environ`
fi

# Now finally run bash.

exec bash
