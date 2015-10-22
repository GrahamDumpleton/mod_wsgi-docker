FROM grahamdumpleton/mod-wsgi-docker:python-3.3

WORKDIR /app

ONBUILD COPY . /app

ONBUILD RUN mod_wsgi-docker-build

EXPOSE 80

ENTRYPOINT [ "mod_wsgi-docker-start" ]
