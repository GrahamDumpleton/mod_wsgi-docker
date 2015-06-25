FROM debian:jessie

ENV PYTHON_VERSION=2.7.10 \
    APR_VERSION=1.5.2 \
    APR_UTIL_VERSION=1.5.4 \
    APACHE_VERSION=2.4.12 \
    MOD_WSGI_VERSION=4.4.13

COPY setup.sh /usr/local/bin/mod_wsgi-docker-setup

RUN /usr/local/bin/mod_wsgi-docker-setup

COPY build.sh /usr/local/bin/mod_wsgi-docker-build
COPY start.sh /usr/local/bin/mod_wsgi-docker-start
COPY shell.sh /usr/local/bin/mod_wsgi-docker-shell

ENV LANG=en_US.UTF-8 PYTHONHASHSEED=random \
    PATH=/usr/local/python/bin:/usr/local/apache/bin:$PATH \
    MOD_WSGI_USER=www-data MOD_WSGI_GROUP=www-data

WORKDIR /app
