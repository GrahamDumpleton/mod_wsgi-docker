#!/bin/bash

set -x
set -eo pipefail

docker push grahamdumpleton/mod-wsgi-docker:python-2.7
docker push grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild
docker push grahamdumpleton/mod-wsgi-docker:python-3.3
docker push grahamdumpleton/mod-wsgi-docker:python-3.3-onbuild
docker push grahamdumpleton/mod-wsgi-docker:python-3.4
docker push grahamdumpleton/mod-wsgi-docker:python-3.4-onbuild
docker push grahamdumpleton/mod-wsgi-docker:python-3.5
docker push grahamdumpleton/mod-wsgi-docker:python-3.5-onbuild
