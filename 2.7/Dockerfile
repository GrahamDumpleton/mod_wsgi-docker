FROM debian:jessie

RUN apt-get update && \
    apt-get install -y ca-certificates libssl1.0.0 curl gcc \
        libc6-dev libssl-dev make xz-utils zlib1g-dev libsqlite3-dev \
        libapr1 libapr1-dev libaprutil1 libaprutil1-dev libpcre++0 \
        libpcre++-dev python-pip python-virtualenv virtualenv \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

RUN mkdir -p /app /app/.build && virtualenv /app/.build/env

COPY requirements.txt /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    pip install -U -r requirements.txt && buildout init
    
COPY buildout.cfg /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    buildout -v -v

RUN rm -rf /app/.build

RUN apt-get purge -y python.* libpython.* virtualenv

ENV PATH /app/.vendor/python/bin:/app/.vendor/apache/bin:$PATH

RUN curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python && \
    pip install virtualenv

RUN pip install https://github.com/GrahamDumpleton/mod_wsgi/archive/cbf54ab64a87d901af48899036c7c9f05b8aaa70.zip

RUN find /app/.vendor/python/lib \
    \( -type d -and -name test -or -name tests \) -or \
    \( -type f -and -name '*.pyc' -or -name '*.pyo' \) | \
    xargs rm -rf

ENV LANG C.UTF-8

WORKDIR /app
