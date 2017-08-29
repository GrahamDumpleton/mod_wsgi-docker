FROM debian:jessie

ENV PYTHON_VERSION=3.3.6 \
    NGHTTP2_VERSION=1.25.0 \
    APR_VERSION=1.6.2 \
    APR_UTIL_VERSION=1.6.0 \
    APACHE_VERSION=2.4.27 \
    MOD_WSGI_VERSION=4.5.18 \
    NSS_WRAPPER_VERSION=1.1.3 \
    TINI_VERSION=0.16.1

COPY install.sh /usr/local/bin/mod_wsgi-docker-install

RUN /usr/local/bin/mod_wsgi-docker-install

COPY setup.sh /usr/local/bin/mod_wsgi-docker-setup

RUN /usr/local/bin/mod_wsgi-docker-setup

COPY build.sh /usr/local/bin/mod_wsgi-docker-build
COPY environ.sh /usr/local/bin/mod_wsgi-docker-environ
COPY entrypoint.sh /usr/local/bin/mod_wsgi-docker-entrypoint
COPY start.sh /usr/local/bin/mod_wsgi-docker-start
COPY shell.sh /usr/local/bin/mod_wsgi-docker-shell

COPY assemble.sh /usr/local/s2i/bin/assemble

RUN cd /usr/local/s2i/bin; ln -s assemble save-artifacts; \
    ln -s assemble run; ln -s assemble usage

LABEL io.k8s.description="Builder for Python web applications." \
      io.k8s.display-name="Apache/mod_wsgi (Python 3.3)" \
      io.openshift.expose-services="80:http" \
      io.openshift.tags="builder,mod_wsgi,python-3.3,mod_wsgi-python-3.3" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i/bin"

ENV STI_SCRIPTS_PATH=/usr/local/s2i/bin

ENV LANG=en_US.UTF-8 PYTHONHASHSEED=random \
    PATH=/usr/local/python/bin:/usr/local/apache/bin:$PATH

# We set 'MOD_WSGI_USER' to special user 'whiskey' and 'MOD_WSGI_GROUP'
# to 'root' as fallback for what user/group mod_wsgi-express should run
# as if not specified and user is root. Best practice though is for a
# derived Docker image to explicitly set the user Docker runs as to a
# non root user.

ENV MOD_WSGI_USER=whiskey MOD_WSGI_GROUP=root

WORKDIR /app
