FROM grahamdumpleton/mod-wsgi-docker:python-2.7

WORKDIR /app

ONBUILD COPY . /app

ONBUILD RUN chown -R $MOD_WSGI_USER:$MOD_WSGI_GROUP /app

ONBUILD RUN mod_wsgi-docker-build

EXPOSE 80
ENTRYPOINT [ "mod_wsgi-docker-start" ]
