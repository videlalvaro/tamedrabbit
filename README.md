# RabbitMQ Standalone Release #

This repo hosts the file `release.branch.diff` that can be applied to the
[rabbitmq-server](http://hg.rabbitmq.com/rabbitmq-server/) repo
to add a make target that allows you to create a rabbitmq release that includes the Erlang
runtime system (erts).

Inside the downloads folder you can find the standalone release file
[rabbitmq-server-osx-2.8.1u.tar.gz](https://raw.github.com/videlalvaro/rabbitmq-release/master/downloads/rabbitmq-server-osx-2.8.1u.tar.gz).
Feel free to untar it and test it on your Mac.

The release has been built with `Erlang R15B01 (erts-5.9.1)` on a Mac with **OSX Lion**.

Read the instructions located in the realted README file to see how to run the server.

# Idea #

The idea of generating that relase is to provide an easy to use RabbitMQ distribution that can
be used for development. By easy to use it means that you don't need to build/install Erlang to
run the server since a minimal erlang distribuion is self contained there.

Also the rabbitmq-management plugin is pre installed so you have a friendly user interface
that you can use to interact with RabbitMQ.

# Running the new rlsdist target #

Before trying this make sure you have installed the required tools listed
[here](http://www.rabbitmq.com/build-server.html)

    hg clone http://hg.rabbitmq.com/rabbitmq-public-umbrella/
    cd rabbitmq-public-umbrella
    hg checkout 93ffc675897c
    make co
    cd rabbitmq
    hg checkout 7df76eda4753
    hg import --no-commit path/to/release.branch.diff
    cd ..
    make release VERSION=2.8.1u
    cd rabbitmq-server
    make plugins PLUGINS_SRC_DIR=".." VERSION=2.8.1u
    chmod +x pre-release/scripts/make_rel
    make rlsdist VERSION=2.8.1u PLUGINS_SRC_DIR=..

Your new release file will be inside:

`rabbitmq-server/pre-release/build/rabbitmq-server-2.8.1u.tar.gz`

# NOTE #

This release is unofficial and not supported by the RabbitMQ. If something doesn't work blame me
and file an issue on this repo.

# LICENSE #

This work is licensed under the Mozilla Public License as stated here: [http://www.rabbitmq.com/mpl.html](http://www.rabbitmq.com/mpl.html).

The Erlang ERTS is distrubted according to the Erlang Public License: [http://www.erlang.org/EPLICENSE](http://www.erlang.org/EPLICENSE)
