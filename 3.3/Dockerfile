FROM buildpack-deps

RUN apt-get update && \
    apt-get install -y python-pip python-virtualenv libapr1 libaprutil1 \
        libpcre++0 libapr1-dev libaprutil1-dev libpcre++-dev && \
    rm -r /var/lib/apt/lists/*

RUN mkdir -p /app /app/.build && virtualenv /app/.build/env

COPY requirements.txt /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    pip install -U -r requirements.txt && buildout init
    
COPY buildout.cfg /app/.build/

RUN cd /app/.build && PATH=/app/.build/env/bin:$PATH && \
    buildout -v -v

RUN cd /app/.vendor/python/bin && \
    ln -s easy_install-3.3 easy_install && \
    ln -s idle3 idle && \
    ln -s pydoc3 pydoc && \
    ln -s python3 python && \
    ln -s python-config3 python-config

RUN rm -rf /app/.build

RUN apt-get purge -y python python-minimal python2.7-minimal
RUN apt-get purge -y python3 python3-minimal

ENV PATH /app/.vendor/python/bin:/app/.vendor/apache/bin:$PATH

RUN curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python && \
    pip install virtualenv

RUN pip install https://github.com/GrahamDumpleton/mod_wsgi/archive/cbf54ab64a87d901af48899036c7c9f05b8aaa70.zip

ENV LANG C.UTF-8

WORKDIR /app
