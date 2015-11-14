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

rm -r /var/lib/apt/lists/* 

apt-get update

# Install all the dependencies that we need in order to be able to build
# both Python and Apache from source code, and then build additional
# modules for each. This is still a slim install. If additional packages
# are needed based on users code, such as database clients, they should
# be installed by the user from the build hooks.

apt-get install -y ca-certificates locales curl gcc g++ file make cmake \
    xz-utils mime-support libbz2-dev libc6-dev libdb-dev libexpat1-dev \
    libffi-dev  libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev \
    libtinfo-dev zlib1g-dev libpcre++-dev vim less --no-install-recommends

# Ensure that default language locale is set to a sane default of UTF-8.

echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen

locale-gen

LANG=en_US.UTF-8
export LANG

# Set up the directory where Python and Apache installations will be put.

INSTALL_ROOT=/usr/local
export INSTALL_ROOT

BUILD_ROOT=/tmp/build
export BUILD_ROOT

mkdir -p $INSTALL_ROOT
mkdir -p $BUILD_ROOT

# Validate that package version details are set in the Dockerfile.

test ! -z "$PYTHON_VERSION" || exit 1

test ! -z "$NGHTTP2_VERSION" || exit 1
test ! -z "$APR_VERSION" || exit 1
test ! -z "$APR_UTIL_VERSION" || exit 1
test ! -z "$APACHE_VERSION" || exit 1

test ! -z "$MOD_WSGI_VERSION" || exit 1

test ! -z "$NSS_WRAPPER_VERSION" || exit 1

# Download source code for packages and unpack them.

curl -SL -o $BUILD_ROOT/python.tar.gz https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz

mkdir $BUILD_ROOT/python

tar -xC $BUILD_ROOT/python --strip-components=1 -f $BUILD_ROOT/python.tar.gz

curl -SL -o $BUILD_ROOT/nghttp2.tar.gz https://github.com/tatsuhiro-t/nghttp2/releases/download/v$NGHTTP2_VERSION/nghttp2-$NGHTTP2_VERSION.tar.gz

mkdir $BUILD_ROOT/nghttp2

tar -xC $BUILD_ROOT/nghttp2 --strip-components=1 -f $BUILD_ROOT/nghttp2.tar.gz

curl -SL -o $BUILD_ROOT/apr.tar.gz http://mirror.ventraip.net.au/apache/apr/apr-$APR_VERSION.tar.gz

mkdir $BUILD_ROOT/apr

tar -xC $BUILD_ROOT/apr --strip-components=1 -f $BUILD_ROOT/apr.tar.gz

curl -SL -o $BUILD_ROOT/apr-util.tar.gz http://mirror.ventraip.net.au/apache/apr/apr-util-$APR_UTIL_VERSION.tar.gz

mkdir $BUILD_ROOT/apr-util

tar -xC $BUILD_ROOT/apr-util --strip-components=1 -f $BUILD_ROOT/apr-util.tar.gz

curl -SL -o $BUILD_ROOT/apache.tar.gz http://mirror.ventraip.net.au/apache/httpd/httpd-$APACHE_VERSION.tar.gz

mkdir $BUILD_ROOT/apache

tar -xC $BUILD_ROOT/apache --strip-components=1 -f $BUILD_ROOT/apache.tar.gz

curl -SL -o $BUILD_ROOT/nss_wrapper.tar.gz https://ftp.samba.org/pub/cwrap/nss_wrapper-$NSS_WRAPPER_VERSION.tar.gz

mkdir $BUILD_ROOT/nss_wrapper

tar -xC $BUILD_ROOT/nss_wrapper --strip-components=1 -f $BUILD_ROOT/nss_wrapper.tar.gz

# To be safe, force the C compiler to be used to be the 64 bit compiler.

CC=x86_64-linux-gnu-gcc
export CC

# Build Python from source code. Configure options used in part mirror
# what is used by Debian itself when it builds its own Python packages.
# We first install with a shared Python library, and then install the
# static library and statically linked 'python' executable.

cd $BUILD_ROOT/python

CONFIG_ARGS="--prefix=$INSTALL_ROOT/python \
    --enable-ipv6 --with-dbmliborder=bdb:gdbm --with-system-expat \
    --with-system-ffi --with-fpectl"

case "$PYTHON_VERSION" in
    2.*)
        CONFIG_ARGS="$CONFIG_ARGS --enable-unicode=ucs4"
        ;;
    3.[012].*)
        CONFIG_ARGS="$CONFIG_ARGS --with-wide-unicode"
        ;;
esac

./configure $CONFIG_ARGS --enable-shared

LD_RUN_PATH=$INSTALL_ROOT/python/lib
export LD_RUN_PATH

make
make install
make distclean

./configure $CONFIG_ARGS

make
make altbininstall

unset LD_RUN_PATH

cd $INSTALL_ROOT/python/bin

case "$PYTHON_VERSION" in
    3.*)
        ln -s python3 python
        ;;
esac

# Build Apache from source code.

cd $BUILD_ROOT/nghttp2

./configure --prefix=$INSTALL_ROOT/nghttp2

make
make install

cd $BUILD_ROOT/apr

./configure --prefix=$INSTALL_ROOT/apache

make
make install

cd $BUILD_ROOT/apr-util

./configure --prefix=$INSTALL_ROOT/apache \
    --with-apr=$INSTALL_ROOT/apache/bin/apr-1-config

make
make install

cd $BUILD_ROOT/apache

./configure --prefix=$INSTALL_ROOT/apache --enable-mpms-shared=all \
    --with-mpm=event --enable-so --enable-rewrite --enable-http2 \
    --with-apr=$INSTALL_ROOT/apache/bin/apr-1-config \
    --with-apr-util=$INSTALL_ROOT/apache/bin/apu-1-config \
    --with-nghttp2=$INSTALL_ROOT/nghttp2

make
make install

# Because the recommendation is that the derived Docker image should run
# as a non root user, we enable the ability for Apache 'httpd'  when run
# as a non root user to bind privileged ports normally used by system
# services. This allows it to use port 80 and 443 as would normally be
# used for HTTP/HTTPS. Allowing use of 80/443 can avoid problems with
# some web applications that don't calculate properly what the web
# services public port is and instead wrongly use the ports that the
# Docker container exposes it as, which can be something different when
# a front end proxy or router is used.

setcap 'cap_net_bind_service=+ep' $INSTALL_ROOT/apache/bin/httpd

# Build nss_wrapper package for use in returning proper user/group
# details if container run under random uid/gid.

cd $BUILD_ROOT/nss_wrapper

mkdir obj
cd obj

cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_ROOT/nss_wrapper -DLIB_SUFFIX=64 ..

make
make install

# Set PATH to include bin directories for Python and Apache.

PATH=$INSTALL_ROOT/python/bin:$INSTALL_ROOT/apache/bin:$PATH
export PATH

# Install additional common Python packages we want installed. We always
# attempt to force installation of the latest version of pip.
#
# Note that this includes installing mod_wsgi-express as a fallback in
# case someone expects it to be available as part of the base image. We
# install it again as part of the build, in that case as part of the
# Python virtual environment that is created.

curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python

if test ! -f $INSTALL_ROOT/python/bin/pip; then
    if test -f $INSTALL_ROOT/python/bin/pip3; then
        ln -s pip3 $INSTALL_ROOT/python/bin/pip
    fi
fi

pip install --no-cache-dir virtualenv

pip install --no-cache-dir -U pip

pip install --no-cache-dir -U mod_wsgi==$MOD_WSGI_VERSION

# Prune unwanted files from Python and Apache installations.

find $INSTALL_ROOT/python/lib \
    \( -type d -and -name test -or -name tests \) -or \
    \( -type f -and -name '*.pyc' -or -name '*.pyo' \) | \
    xargs rm -rf

rm -rf $INSTALL_ROOT/apache/manual

# Clean up the temporary build area.

rm -rf $BUILD_ROOT

# Clean up the package index.

rm -r /var/lib/apt/lists/*

# Create empty directory for home directory of www-data user. Ensure it is
# world writable but also has the sticky bit so only root or the owner
# can unlink any files. Needs to be world writable as we cannot be
# certain what uid application will run as.

mkdir -p /var/www
chown www-data:www-data /var/www
chmod 1777 /var/www

# Create empty directory to be used as application directory.

mkdir -p /app

# Create empty directory to be used as the data directory. Ensure it is
# world writable but also has the sticky bit so only root or the owner
# can unlink any files. Needs to be world writable as we cannot be
# certain what uid application will run as.

mkdir -p /data
chmod 1777 /data

# Create empty directory to be used as the temporary runtime directory.
# Ensure it is world writable but also has the sticky bit so only root
# or the owner can unlink any files. Needs to be world writable as we
# cannot be certain what uid application will run as.

mkdir -p /.whiskey
chmod 1777 /.whiskey
