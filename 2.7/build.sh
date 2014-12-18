#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# This is the script that prepares the Python application to be run. It
# would normally be triggered from a derived docker image explicitly, or
# as a deferred ONBUILD action.
#
# The main purpose of the script is to run 'pip install' on any user
# supplied 'requirements.txt' file. In addition to that though, it will
# also run any user provided scripts for performing actions before or
# after the installation of any application dependencies. These user
# scripts enable the ability to install additional system packages, or
# run any application specific startup commands for preparing an
# application, such as for running 'collectstatic' on a Django web
# application.

# Ensure that any failure within this script or a user provided script
# causes this script to fail immediately. This eliminates the need to
# check individual statuses for anything which is run and prematurely
# exit. Note that the feature of bash to exit in this way isn't
# foolproof. Ensure that you heed any advice in:
#
#   http://mywiki.wooledge.org/BashFAQ/105
#   http://fvue.nl/wiki/Bash:_Error_handling
#
# and use best practices to ensure that failures are always detected.
# Any user supplied scripts should also use this failure mode.

set -eo pipefail

# Make sure we are in the correct working directory for the application.

cd /app

# Create the '.docker/user_vars' directory for storage of user defined
# environment variables if it doesn't already exist. These can be
# created by the user from any hook script. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to.

mkdir -p .docker/user_vars

# Run any user supplied script to be run prior to installing application
# dependencies. This is to allow additional system packages to be
# installed that may be required by any Python modules which are being
# installed. The script must be executable in order to be run. It is not
# possible for this script to change the permissions so it is executable
# and then run it, due to some docker bug which results in the text file
# being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -x .docker/action_hooks/pre-build ]; then
    echo " -----> Running .docker/action_hooks/pre-build"
    .docker/action_hooks/pre-build
fi

# Check for the existance of a 'requirements.txt' file for 'pip'. If
# there isn't, but there is a 'setup.py' file, assume that the directory
# is a package that needs to be installed.

if [ ! -f requirements.txt ]; then
    if [ -f setup.py ]; then
        echo "-e ." > requirements.txt
    fi
fi

# Check whether there are any git repositories referenced from the
# 'requirements.txt file. If there are then we need to first explicitly
# install git and only then run 'pip'.

if [ -f requirements.txt ]; then
    if (grep -Fiq "git+" requirements.txt); then
        echo " -----> Installing git"
        apt-get update && \
            apt-get install -y git --no-install-recommends && \
            rm -r /var/lib/apt/lists/*
    fi
fi

# Check whether there are any Mercurial repositories referenced from the
# 'requirements.txt file. If there are then we need to first explicitly
# install Mercurial and only then run 'pip'.

if [ -f requirements.txt ]; then
    if (grep -Fiq "hg+" requirements.txt); then
        echo " -----> Installing mercurial"
        pip install -U mercurial
    fi
fi

# Now run 'pip' to install any required Python packages based on the
# contents of the 'requirements.txt' file.

if [ -f requirements.txt ]; then
    echo " -----> Installing dependencies with pip"
    pip install -r requirements.txt -U --allow-all-external \
        --exists-action=w --src=.docker/tmp
fi

# Run any user supplied script to run after installing any application
# dependencies. This is to allow any application specific setup scripts
# to be run, such as 'collectstatic' for a Django web application. It is
# not possible for this script to change the permissions so it is
# executable and then run it, due to some docker bug which results in
# the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -x .docker/action_hooks/build ]; then
    echo " -----> Running .docker/action_hooks/build"
    .docker/action_hooks/build
fi

# Clean up any temporary files, including the results of checking out
# any source code repositories when doing a 'pip install' from a VCS.

rm -rf .docker/tmp
