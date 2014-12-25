# python-3.3

FROM debian:jessie

RUN rm -r /var/lib/apt/lists/* && apt-get update && \
    apt-get install -y ca-certificates locales libssl1.0.0 curl gcc file \
        libc6-dev libssl-dev make xz-utils zlib1g-dev libsqlite3-dev \
        libpcre++0 libpcre++-dev python-pip python-virtualenv virtualenv \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8

RUN mkdir -p /app /app/.build && virtualenv /app/.build/env

COPY requirements.txt /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    pip install -U -r requirements.txt && buildout init
    
COPY buildout.cfg /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    buildout -v -v

RUN cd /app/.whiskey/python/bin && \
    ln -s easy_install-3.3 easy_install && \
    ln -s idle3 idle && \
    ln -s pydoc3 pydoc && \
    ln -s python3 python && \
    ln -s python-config3 python-config

RUN rm -rf /app/.build

RUN apt-get purge -y python.* libpython.* virtualenv

ENV PATH /app/.whiskey/python/bin:$PATH

RUN curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python && \
    pip install virtualenv

RUN find /app/.whiskey/python/lib \
    \( -type d -and -name test -or -name tests \) -or \
    \( -type f -and -name '*.pyc' -or -name '*.pyo' \) | \
    xargs rm -rf

RUN mkdir /app/.whiskey/scripts

COPY build.sh /app/.whiskey/python/bin/mod_wsgi-docker-build
COPY start.sh /app/.whiskey/python/bin/mod_wsgi-docker-start
COPY shell.sh /app/.whiskey/python/bin/mod_wsgi-docker-shell

ENV PYTHONHASHSEED random

ENV WSGI_RUN_USER www-data
ENV WSGI_RUN_GROUP www-data

WORKDIR /app
