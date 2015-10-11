FROM debian:jessie

ENV PYTHON_VERSION=2.7.10 \
    APR_VERSION=1.5.2 \
    APR_UTIL_VERSION=1.5.4 \
    APACHE_VERSION=2.4.16 \
    MOD_WSGI_VERSION=4.4.16

COPY setup.sh /usr/local/bin/mod_wsgi-docker-setup

RUN /usr/local/bin/mod_wsgi-docker-setup

COPY build.sh /usr/local/bin/mod_wsgi-docker-build
COPY start.sh /usr/local/bin/mod_wsgi-docker-start
COPY shell.sh /usr/local/bin/mod_wsgi-docker-shell

ENV LANG=en_US.UTF-8 PYTHONHASHSEED=random \
    PATH=/usr/local/python/bin:/usr/local/apache/bin:$PATH

# We set 'MOD_WSGI_USER' and 'MOD_WSGI_GROUP' to 'www-data' as fallback
# for what user/group mod_wsgi-express should run as if not specified
# and user is root. Best practice though is for a derived Docker image
# to explicitly set the user Docker runs as to a non root user. As all
# file permissions are set to the 'www-data' user then preferable that
# it be used. Do note that to satisfy requirements of some deployment
# scenarios, rather than setting 'USER' as 'www-data', then it should be
# set to the uid '33'. If allowed, the 'MOD_WSGI_USER_ID' environment
# variable is provided and it can be supplied to 'USER' to pick up the
# uid of the default user.

ENV MOD_WSGI_USER=www-data MOD_WSGI_USER_ID=33 MOD_WSGI_GROUP=www-data

WORKDIR /app
