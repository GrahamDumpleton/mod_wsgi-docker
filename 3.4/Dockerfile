# python-3.4

FROM debian:jessie

RUN rm -r /var/lib/apt/lists/* && apt-get update && \
    apt-get install -y ca-certificates locales libssl1.0.0 curl gcc file \
        libc6-dev libssl-dev make xz-utils zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev libpcre++0 libpcre++-dev python-pip \
        python-virtualenv virtualenv --no-install-recommends && \
        rm -r /var/lib/apt/lists/*

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8

RUN mkdir -p /.whiskey /.whiskey/build && virtualenv /.whiskey/build/env

COPY requirements.txt /.whiskey/build/

RUN cd /.whiskey/build && PATH=/.whiskey/build/env/bin:$PATH && \
    pip install -U -r requirements.txt && buildout init
    
COPY buildout.cfg /.whiskey/build/

RUN cd /.whiskey/build && PATH=/.whiskey/build/env/bin:$PATH && \
    buildout -v -v

RUN cd /.whiskey/python/bin && \
    ln -s easy_install-3.4 easy_install && \
    ln -s idle3 idle && \
    ln -s pip3 pip && \
    ln -s pydoc3 pydoc && \
    ln -s python3 python && \
    ln -s python-config3 python-config

RUN rm -rf /.whiskey/build

RUN apt-get purge -y python.* libpython.* virtualenv

RUN cp /.whiskey/apache/bin/apxs /.whiskey/python/bin/ && \
    cp /.whiskey/apache/bin/httpd /.whiskey/python/bin/ && \
    cp /.whiskey/apache/bin/rotatelogs /.whiskey/python/bin/ && \
    cp /.whiskey/apache/bin/ab /.whiskey/python/bin/

ENV PATH /.whiskey/python/bin:$PATH

RUN pip install --no-cache-dir virtualenv && \
    pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -U mod_wsgi==4.4.13

RUN find /.whiskey/python/lib \
    \( -type d -and -name test -or -name tests \) -or \
    \( -type f -and -name '*.pyc' -or -name '*.pyo' \) | \
    xargs rm -rf

COPY build.sh /.whiskey/python/bin/mod_wsgi-docker-build
COPY start.sh /.whiskey/python/bin/mod_wsgi-docker-start
COPY shell.sh /.whiskey/python/bin/mod_wsgi-docker-shell

ENV PYTHONHASHSEED random

ENV MOD_WSGI_USER www-data
ENV MOD_WSGI_GROUP www-data

RUN mkdir -p /app

WORKDIR /app
