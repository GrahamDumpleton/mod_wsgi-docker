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

# Run any user supplied script to be run prior to starting the
# application in the actual container. The script must be executable in
# order to be run. It is not possible for this script to change the
# permissions so it is executable and then run it, due to some docker
# bug which results in the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -x .docker/action_hooks/deploy ]; then
    echo " -----> Running .docker/action_hooks/deploy"
    .docker/action_hooks/deploy
fi

# Now run the the actual application. This is run in the background. It
# will log to stdout/stderr.

PORT=${PORT:-80}

mod_wsgi-express start-server --log-to-terminal --startup-log \
    --port "${PORT}" "$@" &

# Run any user supplied script to be run after starting the application
# in the actual container. The script must be executable in order to be
# run. It is not possible for this script to change the permissions so
# it is executable and then run it, due to some docker bug which results
# in the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -x .docker/action_hooks/post-deploy ]; then
    echo " -----> Running .docker/action_hooks/post-deploy"
    .docker/action_hooks/post-deploy &
fi

# Now wait for all child processes to exit. Under normal circumstances
# this should block until a signal has been received by the container
# telling it to shutdown.

wait
