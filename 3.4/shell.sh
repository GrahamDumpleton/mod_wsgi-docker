#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# This script will run an interactive bash shell.

# Docker will have set any environment variables defined in the image or
# on the command line when the container has been run. Here we are going
# to look for any statically defined environment variables provided by
# the user as part of the actual application. These will have been
# placed in the '.docker/user_vars' directory. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to. Each of the
# environment variables is set and exported.

envvars=

for name in `ls .docker/user_vars`; do
    export $name=`cat .docker/user_vars/$name`
    envvars="$envvars $name"
done

# Run any user supplied script to be run to set, modify or delete the
# environment variables.

if [ -x .docker/action_hooks/deploy-env ]; then
    echo " -----> Running .docker/action_hooks/deploy-env"
    .docker/action_hooks/deploy-env
fi

# Go back and reset all the environment variables based on additions or
# changes. Unset any for which the environment variable file no longer
# exists, albeit in practice that is probably unlikely.

for name in `ls .docker/user_vars`; do
    export $name=`cat .docker/user_vars/$name`
done

for name in $envvars; do
    if test ! -f .docker/user_vars/$name; then
        unset $name
    fi
done

# Now finally run bash.

exec bash
