FROM mod_wsgi-express:python-2.7

WORKDIR /app

ONBUILD COPY requirements.txt /app/
ONBUILD RUN pip install -U -r requirements.txt

ONBUILD COPY . /app

EXPOSE 80

ENV WSGI_RUN_USER www-data
ENV WSGI_RUN_GROUP www-data

COPY hello.wsgi /app/.vendor/demos/

ENTRYPOINT ["mod_wsgi-express", "start-server", "--log-to-terminal", "--port=80"]
CMD [ "/app/.vendor/demos/hello.wsgi" ]
