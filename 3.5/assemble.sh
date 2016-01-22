#!/usr/bin/env bash

# The master for this script exists in the Python '2.7' directory. Do
# not edit the version of this script found in other directories. When
# the version of the script in the Python '2.7' directory is modified,
# it must then be be copied into other directories. This is necessary as
# Docker when building an image cannot copy in a file from outside of
# the directory where the Dockerfile resides.
#
# Note that this script contains functionality of all the different S2I
# scripts. It should be placed into the S2I bin directory as "assemble"
# and then links made to it for "usage", "save-artifacts" and "run".

set -eo pipefail

PROGRAM=`basename $0`

usage() {
    PYTHON_VERSION_MN=`echo $PYTHON_VERSION | sed -e 's/\.[^.]*$//'`
    BUILDER_NAME="mod_wsgi-docker-s2i:python-$PYTHON_VERSION_MN"

    cat <<EOF
This is a S2I builder for creating Docker images for Python web applications.

To use the builder, first install S2I from:

    https://github.com/openshift/source-to-image

You can then create a Docker image from a GIT repository by running:

    s2i build git://<source code> $BUILDER_NAME <application image>

The resulting image can then be run as:

    docker run -p 8000:80 <application image>

The S2I builder is also compatible with the builtin support of OpenShift 3
for deploying applications using S2I.
EOF
}

assemble() {
    echo "---> Installing application source"

    cp -Rf /tmp/src/. /app

    echo "---> Building application from source"

    mod_wsgi-docker-build

    # Need to make everything group writable so that 'oc rsync' will
    # work when deploying the image to OpenShift and trying to do live
    # updates in a running container. This means we are even making
    # files which are not writable by the owner writable by the group,
    # but this is the only way to make it work when running container as
    # an arbitrary user ID and relying on group access controls.
    #
    # Note that this will fail to change the permissions of the /app
    # directory itself. We therefore suppress any warnings, but we also
    # need to ignore the exit status as any failure will cause an error
    # exit status even though permissions of remaining files are updated
    # as we require.

    echo "---> Fix permissions on application source"

    chmod -Rf g+w /app || true
}

artifacts() {
    # tar cf - <list of files and folders>

    true
}

run() {
    echo "---> Executing the start up script"

    exec mod_wsgi-docker-start
}

if [ "$PROGRAM" = "usage" ]; then
    usage

    exit 0
fi

if [ "$PROGRAM" = "assemble" -a "$1" = "-h" ]; then
    usage

    exit 0
fi

if [ "$PROGRAM" = "assemble" ]; then
    assemble
    
    exit 0
fi

if [ "$PROGRAM" = "save-artifacts" ]; then
    artifacts
    
    exit 0
fi

if [ "$PROGRAM" = "run" ]; then
    run

    exit 1
fi
