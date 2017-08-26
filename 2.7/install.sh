#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.

# Record everything that is run from this script so appears in logs.

set -x

# Ensure that any failure within this script causes this script to fail
# immediately. This eliminates the need to check individual statuses for
# anything which is run and prematurely exit. Note that the feature of
# bash to exit in this way isn't foolproof. Ensure that you heed any
# advice in:
#
#   http://mywiki.wooledge.org/BashFAQ/105
#   http://fvue.nl/wiki/Bash:_Error_handling
#
# and use best practices to ensure that failures are always detected.
# Any user supplied scripts should also use this failure mode.

set -eo pipefail

# Ensure we have an up to date package index.

rm -rf /var/lib/apt/lists/*

apt-get update

# Install all the dependencies that we need in order to be able to build
# both Python and Apache from source code, and then build additional
# modules for each. This is still a slim install. If additional packages
# are needed based on users code, such as database clients, they should
# be installed by the user from the build hooks.

apt-get install -y ca-certificates locales curl gcc g++ file make cmake \
    xz-utils mime-support libbz2-dev libc6-dev libdb-dev libexpat1-dev \
    libffi-dev  libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev \
    libtinfo-dev zlib1g-dev libpcre++-dev libmysqlclient-dev libpq-dev \
    pkg-config vim less git rsync --no-install-recommends

# Clean up the package index.

rm -r /var/lib/apt/lists/*
