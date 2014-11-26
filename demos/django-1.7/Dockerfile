FROM grahamdumpleton/mod_wsgi-docker:python-2.7-onbuild

CMD [ "--working-directory", "example", \
      "--url-alias", "/static", "example/htdocs", \
      "--application-type", "module", "example.wsgi" ]
