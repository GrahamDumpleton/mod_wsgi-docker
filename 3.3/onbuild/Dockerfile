FROM grahamdumpleton/mod-wsgi-docker:python-3.3

WORKDIR /app

ONBUILD COPY requirements.txt /app/
ONBUILD RUN pip install -U -r requirements.txt

ONBUILD COPY . /app

EXPOSE 80

ENV WSGI_RUN_USER www-data
ENV WSGI_RUN_GROUP www-data

COPY hello.wsgi /app/.vendor/demos/

ENTRYPOINT ["mod_wsgi-express", "start-server", \
 "--server-mpm", "worker", "--log-to-terminal", "--port=80"]

CMD [ "/app/.vendor/demos/hello.wsgi" ]
