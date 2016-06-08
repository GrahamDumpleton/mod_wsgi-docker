#!/bin/bash

set -x
set -eo pipefail

(cd 2.7; docker build -t grahamdumpleton/mod-wsgi-docker:python-2.7 .)
(cd 2.7/onbuild; docker build -t grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild .)

(cd 3.3; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.3 .)
(cd 3.3/onbuild; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.3-onbuild .)

(cd 3.4; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.4 .)
(cd 3.4/onbuild; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.4-onbuild .)

(cd 3.5; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.5 .)
(cd 3.5/onbuild; docker build -t grahamdumpleton/mod-wsgi-docker:python-3.5-onbuild .)
