=================
MOD_WSGI (DOCKER)
=================

The mod_wsgi-docker package is a companion package for Apache/mod_wsgi. It
contains configurations for building docker images which bundle up Apache
and mod_wsgi-express.

Available images
----------------

Prebuilt images available are:

* grahamdumpleton/mod-wsgi-docker:python-2.7
* grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild
* grahamdumpleton/mod-wsgi-docker:python-3.3
* grahamdumpleton/mod-wsgi-docker:python-3.3-onbuild
* grahamdumpleton/mod-wsgi-docker:python-3.4
* grahamdumpleton/mod-wsgi-docker:python-3.4-onbuild
* grahamdumpleton/mod-wsgi-docker:python-3.5
* grahamdumpleton/mod-wsgi-docker:python-3.5-onbuild

See `mod-wsgi-docker <https://registry.hub.docker.com/u/grahamdumpleton/mod-wsgi-docker/>`_
on Docker Hub for more information.

How to use these images
-----------------------

Create a ``Dockerfile`` in your Python web application project::

    FROM grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild
    CMD [ "hello.wsgi" ]

The list of ``CMD`` arguments should consist of the path to the WSGI script
file for the Python web application and any additional arguments you wish
to have supplied to the ``mod_wsgi-express`` command.

These 'onbuild' images include multiple ``ONBUILD`` triggers, which should
be all you need to bootstrap most applications. The build will ``COPY`` the
current directory into ``/app`` and then ``RUN pip install`` on any
``requirements.txt`` file. It is possible to define pre and post hooks to
enable additional system packages to be installed and for additional
application setup to be performed.

You can then build and run the Docker image::

    docker build -t my-python-app .
    docker run -it --rm -p 8000:80 --name my-running-app my-python-app

The Python web application should then be accessible at port 8000 of the
docker host.

Note that although your specific Python web application when run will run
as the non root user ``www-data``, the Apache server itself will initially
start up as the root user. Some Docker runtime environments however may be
set up so as to prohibit you running your container as the root user and
require a non root user from the outset.

If this is the case, you can use::

    FROM grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild
    USER $MOD_WSGI_USER_ID
    CMD [ "hello.wsgi" ]

In the case where the environment is interogating the Docker image before
even running it, doesn't resolve the environment variable correctly when
applying conditional checks, and expects to see an integer UID, then you
should instead use::

    FROM grahamdumpleton/mod-wsgi-docker:python-2.7-onbuild
    USER 33
    CMD [ "hello.wsgi" ]

For additional examples see the 'demos' sub directory.
