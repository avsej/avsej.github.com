---
layout: post
title: "Setup systemd units for Confluent Connect on Fedora"
description: How to configure Confluent Connect to start up as a daemon on Fedora 24
---

It is really great when software is distributed as a binary packages for different platforms in addition to open source
tarballs. But not all of them ship startup scripts, and I can understand it because filesytem hierarchy didn't change a
lot recently and seems like settled in most of the linux distribution, unlike initialization systems. So it is easier to
just produce single RPM package with all files and simple start/stop scripts, rather than determine init evolution in
all distributions and tracking it continuously.

Confluent Platform [http://www.confluent.io](http://www.confluent.io/) does great job on packaging, they also maintain
package repositories, and the only thing missing on my Fedora is those unit files to make their services real
daemons. In this post I'm going to fill this gap.

The boostrap of the Kafka Connect and Control Center described thoroughly in their [Quickstart guide][1], so I will just
enumerate the units here in order.  All daemons are using configuration files installed by the RPMs in their default
locations. Also the units assume that the system will have user called `confluent`, which could be created like this (or
replace `confluent` with `root` or any other user on your system):

    sudo useradd -c 'Confluent Platform' -d /dev/null -s /sbin/nologin confluent
    sudo mkdir /var/lib/{zookeeper,kafka}
    sudo chown -R confluent /var/lib/{zookeeper,kafka}

To determine place, where to install the services defined below, you could use `pkg-config`:

    $ pkg-config systemd --variable=systemdsystemunitdir
    /usr/lib/systemd/system

For example on Fedora 24/25, next script should be located at `/usr/lib/systemd/system/confluent-zookeeper.service`.

## confluent-zookeeper.service

    [Unit]
    Description = Confluent Connect: Zookeeper
    Documentation = http://www.confluent.io
    After = network.target remote-fs.target nss-lookup.target

    [Service]
    SyslogIdentifier = confluent-zookeeper
    User = confluent
    Type = simple
    ExecStart = /usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties

    [Install]
    WantedBy = multi-user.target confluent-kafka.service


## confluent-kafka.service

    [Unit]
    Description = Confluent Connect: Kafka
    Documentation = http://www.confluent.io
    After = network.target remote-fs.target nss-lookup.target confluent-zookeeper.service

    [Service]
    SyslogIdentifier = confluent-kafka
    User = confluent
    Type = simple
    ExecStart = /usr/bin/kafka-server-start /etc/kafka/server.properties

    [Install]
    WantedBy = multi-user.target confluent-schema-registry.service

Schema Registry might start too fast and fail because Kafka service is not ready yet. By adding directive
`ExecStartPre = /usr/bin/sleep 10` to Schema Registry service, we can delay its start for 10 seconds.
Or, which I like more, we would actually handle the failure and restart Schema Registry.

## confluent-schema-registry.service

    [Unit]
    Description = Confluent Connect: Schema Registry
    Documentation = http://www.confluent.io
    After = network.target remote-fs.target nss-lookup.target confluent-kafka.service

    [Service]
    SyslogIdentifier = confluent-schema-registry
    User = confluent
    Type = simple
    ExecStart = /usr/bin/schema-registry-start /etc/schema-registry/schema-registry.properties
    Restart = on-failure
    RestartSec = 10

    [Install]
    WantedBy = multi-user.target confluent-connect-distributed.service

## confluent-connect-distributed.service

    [Unit]
    Description = Confluent Connect: Distributed Mode
    Documentation = http://www.confluent.io
    After = network.target remote-fs.target nss-lookup.target confluent-schema-registry.service

    [Service]
    SyslogIdentifier = confluent-connect
    User = confluent
    Type = simple
    ExecStart = /usr/bin/connect-distributed /etc/kafka/connect-distributed.properties

    [Install]
    WantedBy = multi-user.target confluent-control-center.service

## confluent-control-center.service

This last one is optional, needed if you want to use Confluent Control Center.

    [Unit]
    Description = Confluent Connect: Control Center
    Documentation = http://www.confluent.io
    After = network.target remote-fs.target nss-lookup.target confluent-connect-distributed.service

    [Service]
    SyslogIdentifier = confluent-control-center
    User = confluent
    Type = simple
    ExecStart = /usr/bin/control-center-start /etc/confluent-control-center/control-center.properties

    [Install]
    WantedBy = multi-user.target

Alternatively you can use this shell archive ([confluent-units.shar][2]) to deploy the units with single line:

    curl https://avsej.net/confluent-units.shar | sudo sh -

After copying units just reload systemd and enable them:

    sudo systemctl daemon-reload
    sudo systemctl enable confluent-zookeeper.service \
                          confluent-kafka.service \
                          confluent-schema-registry.service \
                          confluent-connect-distributed.service

And, if you need Control Center:

    sudo systemctl enable confluent-control-center.service

[1]: http://docs.confluent.io/3.0.0/control-center/docs/quickstart.html
[2]: /confluent-units.shar
