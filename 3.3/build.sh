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

WHISKEY_CONFDIR=/.whiskey
export WHISKEY_CONFDIR

# Make sure we are in the correct working directory for the application.

cd $WHISKEY_HOMEDIR

# Create the '.whiskey/user_vars' directory for storage of user defined
# environment variables if it doesn't already exist. These can be
# created by the user from any hook script. The name of the file
# corresponds to the name of the environment variable and the contents
# of the file the value to set the environment variable to.
#
# Note that because the path to the user_vars directory was changed, we
# need to warn about old deprecated name. In case that the user is using
# old name, just symlink the new location to the old.

if test -d .docker/user_vars; then
    echo " -----> Linking deprecated .docker/user_vars"
    echo "WARNING: Use directory .whiskey/user_vars instead."
    ln -s $WHISKEY_HOMEDIR/.docker/user_vars .whiskey/user_vars
else
    test ! -d .whiskey/user_vars && mkdir -p .whiskey/user_vars
fi

# Create a Python virtual environment into which any Python packages
# required by the user will actually be installed. It is done at this
# point as privileges may have been dropped by this point and so may
# not have write access to the original Python installation.
#
# We need to reinstall mod_wsgi-express at this point as it was
# originally installed into the main Python installation, but those
# packages will now be ignored.
#
# Once again we force update of pip in case the version bundled with
# the virtualenv package is not the latest.

virtualenv $WHISKEY_CONFDIR/virtualenv

source $WHISKEY_CONFDIR/virtualenv/bin/activate

pip install --no-cache-dir -U pip

pip install --no-cache-dir -U mod_wsgi==$MOD_WSGI_VERSION

# Run any user supplied script to be run prior to installing application
# dependencies. This is to allow additional system packages to be
# installed that may be required by any Python modules which are being
# installed. The script must be executable in order to be run. It is not
# possible for this script to change the permissions so it is executable
# and then run it, due to some docker bug which results in the text file
# being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547
#
# Note that because path to the action_hooks directory was changed, we
# need to warn about old deprecated name. In case that the user is using
# old name, just symlink the new location to the old. If both exist, then
# this should fail.

if test -d .docker/action_hooks; then
    echo " -----> Linking deprecated .docker/action_hooks"
    echo "WARNING: Use directory .whiskey/action_hooks instead."
    ln -s $WHISKEY_HOMEDIR/.docker/action_hooks .whiskey/action_hooks
fi

if [ -x .whiskey/action_hooks/pre-build ]; then
    echo " -----> Running .whiskey/action_hooks/pre-build"
    .whiskey/action_hooks/pre-build
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

# Check to see if a 'wheelhouse' directory has been provided from which
# 'pip' can source required packages for immediate installation rather
# than having to download then from PyPi.

if [ -d .whiskey/wheelhouse ]; then
    echo " -----> Detected wheelhouse for pip"
    PIP_FIND_LINKS=.whiskey/wheelhouse
    export PIP_FIND_LINKS
fi

# Check whether there are any Mercurial repositories referenced from the
# 'requirements.txt file. If there are then we need to first explicitly
# install Mercurial and only then run 'pip'.

if [ -f requirements.txt ]; then
    if (grep -Fiq "hg+" requirements.txt); then
        echo " -----> Installing mercurial"
        pip install --no-cache-dir -U mercurial
    fi
fi

# Now run 'pip' to install any required Python packages based on the
# contents of the 'requirements.txt' file.

if [ -f requirements.txt ]; then
    echo " -----> Installing dependencies with pip"
    pip install --no-cache-dir -U --allow-all-external \
        --exists-action=w --src=.whiskey/tmp -r requirements.txt
fi

# Run any user supplied script to run after installing any application
# dependencies. This is to allow any application specific setup scripts
# to be run, such as 'collectstatic' for a Django web application. It is
# not possible for this script to change the permissions so it is
# executable and then run it, due to some docker bug which results in
# the text file being busy. For more details see:
#
#   https://github.com/docker/docker/issues/9547

if [ -x .whiskey/action_hooks/build ]; then
    echo " -----> Running .whiskey/action_hooks/build"
    .whiskey/action_hooks/build
fi

# Clean up any temporary files, including the results of checking out
# any source code repositories when doing a 'pip install' from a VCS.

rm -rf .whiskey/tmp
