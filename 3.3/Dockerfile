FROM debian:jessie

ENV LANG C.UTF-8

RUN rm -r /var/lib/apt/lists/* && apt-get update && \
    apt-get install -y ca-certificates libssl1.0.0 curl gcc file \
        libc6-dev libssl-dev make xz-utils zlib1g-dev libsqlite3-dev \
        libpcre++0 libpcre++-dev python-pip python-virtualenv virtualenv \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

RUN mkdir -p /app /app/.build && virtualenv /app/.build/env

COPY requirements.txt /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    pip install -U -r requirements.txt && buildout init
    
COPY buildout.cfg /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    buildout -v -v

RUN cd /app/.docker/python/bin && \
    ln -s easy_install-3.3 easy_install && \
    ln -s idle3 idle && \
    ln -s pydoc3 pydoc && \
    ln -s python3 python && \
    ln -s python-config3 python-config

RUN rm -rf /app/.build

RUN apt-get purge -y python.* libpython.* virtualenv

ENV PATH /app/.docker/python/bin:/app/.docker/apache/bin:$PATH

RUN curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python && \
    pip install virtualenv

RUN pip install https://github.com/GrahamDumpleton/mod_wsgi/archive/ee330fec18b8caafb10b3e517fff75bd58a0d974.zip

RUN find /app/.docker/python/lib \
    \( -type d -and -name test -or -name tests \) -or \
    \( -type f -and -name '*.pyc' -or -name '*.pyo' \) | \
    xargs rm -rf

RUN mkdir /app/.docker/scripts

COPY build.sh /app/.docker/scripts/mod_wsgi-docker-build
COPY start.sh /app/.docker/scripts/mod_wsgi-docker-start
COPY shell.sh /app/.docker/scripts/mod_wsgi-docker-shell

ENV PATH /app/.docker/scripts:$PATH

ENV PYTHONHASHSEED random

ENV WSGI_RUN_USER www-data
ENV WSGI_RUN_GROUP www-data

WORKDIR /app
