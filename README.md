# RabbitMQ Standalone Release #

In this repo you can find RabbitMQ packaged as a Mac OSX app that looks like this:

![RabbitMQ.app](https://github.com/videlalvaro/rabbitmq-release/raw/master/images/rabbit_app.png)

You can download the app here [http://dl.dropbox.com/u/58659506/RabbitMQ-2.8.1u.dmg](http://dl.dropbox.com/u/58659506/RabbitMQ-2.8.1u.dmg).

Inside the downloads folder you can find the standalone release file
[rabbitmq-server-osx-2.8.1u.tar.gz](https://raw.github.com/videlalvaro/rabbitmq-release/master/downloads/rabbitmq-server-osx-2.8.1u.tar.gz).
Feel free to untar it and test it on your Mac.

The release has been built with `Erlang R15B01 (erts-5.9.1)` on a Mac with **OSX Lion**.

Read the instructions located in the realted README file to see how to run the server.

## Idea ##

The idea of generating that relase is to provide an easy to use RabbitMQ distribution that can
be used for development. By easy to use it means that you don't need to build/install Erlang to
run the server since a minimal Erlang distribuion is self contained there.

Also the rabbitmq-management plugin is pre installed so you have a friendly user interface
that you can use to interact with RabbitMQ.

## Building it yourself ##

Before trying this make sure you have installed the required tools listed
[here](http://www.rabbitmq.com/build-server.html)

This requires `curl` installed.

    $ git clone git://github.com/videlalvaro/tamedrabbit.git
    $ cd tammedrabbit
    $ make release VERSION=2.8.1

Your new release file will be inside:

`tammedrabbit/pre-release/build/rabbitmq-server-<VERSION>u.tar.gz`

Note that we add an 'u' to the VERSION number to note that this release is _unofficial_.

Note that `VERSION` must be one of the RabbitMQ official releases. One of the make targets will attempt to fetch RabbitMQ' source code from here: [http://www.rabbitmq.com/releases/rabbitmq-server/](http://www.rabbitmq.com/releases/rabbitmq-server/) based on the version number you provide.

You can customize the enabled plugins by providing the varialbe `PLUGINS` with a comma separated list of plugins. Only officially provided plugins are supported. For example you could create a release like this:

    $ make release VERSION=2.8.1 PLUGINS="rabbitmq_management,rabbitmq_shovel"

# NOTE #

This release is unofficial and not supported by the RabbitMQ team. If something doesn't work file an issue on this repo.

# LICENSE #

This work is licensed under the Mozilla Public License as stated here: [http://www.rabbitmq.com/mpl.html](http://www.rabbitmq.com/mpl.html).

The Erlang ERTS is distributed according to the Erlang Public License: [http://www.erlang.org/EPLICENSE](http://www.erlang.org/EPLICENSE)
