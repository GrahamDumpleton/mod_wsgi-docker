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

See `mod_wsgi-docker <https://registry.hub.docker.com/u/grahamdumpleton/mod-wsgi-docker/>`_
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
be all you need to bootstrap most applications. The build will ``COPY`` a
``requirements.txt`` file, ``RUN pip install`` on said file, and then copy
the current directory into ``/app``.

You can then build and run the Docker image::

    docker build -t my-python-app .
    docker run -it --rm -p 8000:80 --name my-running-app my-python-app

The Python web application should then be accessible at port 8000 of the
docker host.

For additional examples see the 'demos' sub directory.
