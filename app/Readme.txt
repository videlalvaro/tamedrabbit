# RabbitMQ App #

This Application packages a standalone RabbitMQ broker that can be run without the need to install Erlang.

It comes with the RabbitMQ Management Plugin already enabled.

## Configuration ##

Server settings:

host: localhost
port: 5672
vhost: /
user: guest
password: guest

Management console settings:

user: guest
password: guest

Once you start the application you will be asked to enter a user and a password to login into the management console. Use guest:guest. Of course you can change them later.

## Where to go from here ##

The next thing to do is to write your own publishers and consumers. To learn how to do that you can read the official tutorials here: http://www.rabbitmq.com/getstarted.html or get the book RabbitMQ in Action co-authored by Alvaro Videla, the creator of this package. You can buy a copy of the book here http://www.manning.com/videla/

## Issues ##

If you find any issues please report them here https://github.com/videlalvaro/rabbitmq-release/issues

## NOTE ##

This release is unofficial as in not related with the RabbitMQ Team nor supported by them.

## License ##

This work is licensed under the Mozilla Public License as stated here: http://www.rabbitmq.com/mpl.html.

The Erlang ERTS is distributed according to the Erlang Public License: http://www.erlang.org/EPLICENSE

