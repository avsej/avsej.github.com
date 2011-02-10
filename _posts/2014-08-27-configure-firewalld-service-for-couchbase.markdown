---
layout: post
title: "Configure FirewallD Service for Couchbase"
description: How to configure custom firewalld service on example of Couchbase Service
---

Fedora linux distribution has nice dynamically managed firewall. One
of its cool features is ability to define groups of ports and manage
them using symbolic name. They called services, and by default
firewalld ships several predefined ones:


    $ firewall-cmd --get-services
    amanda-client amanda-k5-client bacula bacula-client dhcp dhcpv6
    dhcpv6-client dns freeipa-ldap freeipa-ldaps freeipa-replication
    ftp high-availability http https imaps ipp ipp-client ipsec
    kerberos kpasswd ldap ldaps libvirt libvirt-tls mdns mountd ms-wbt
    mysql nfs ntp openvpn pmcd pmproxy pmwebapi pmwebapis pop3s
    postgresql privoxy proxy-dhcp puppetmaster radius rpc-bind samba
    samba-client sane smtp ssh synergy telnet tftp tftp-client
    tor-socks transmission-client vnc-server wbem-https xmpp-bosh
    xmpp-client xmpp-local xmpp-server

I did not found HTML version of
[doc/xml/firewalld.service.xml][firewalld.service.xml], so here is
just kind of example to this document. Because there no predefined
service for couchbase, and also because the server itself uses a lot
of network ports, I will use it here as the sample application.

To add new service, all you need is to create
`/etc/firewalld/services/couchbase.xml` (which might vary, on CentOS 7 it is
`/usr/lib/firewalld/services`) with the following contents:

    <service version="1.0">
      <short>couchbase</short>
      <port protocol="tcp" port="8091"/>        <!-- web console -->
      <port protocol="tcp" port="18091"/>       <!-- web console SSL -->
      <port protocol="tcp" port="8092"/>        <!-- views, XDCR -->
      <port protocol="tcp" port="18092"/>       <!-- views SSL -->
      <port protocol="tcp" port="8093"/>        <!-- N1QL -->
      <port protocol="tcp" port="18093"/>       <!-- N1QL SSL -->
      <port protocol="tcp" port="8094"/>        <!-- Full Text -->
      <port protocol="tcp" port="9100-9105"/>   <!-- indexing ports -->
      <port protocol="tcp" port="11209"/>       <!-- binary SSL -->
      <port protocol="tcp" port="11210"/>       <!-- binary -->
      <port protocol="tcp" port="11211"/>       <!-- ascii/binary memcached legacy -->
      <port protocol="tcp" port="11214-11215"/> <!-- XDCR SSL -->
      <port protocol="tcp" port="4369"/>        <!-- erlang port mapper -->
      <port protocol="tcp" port="21100-21199"/> <!-- node data exchange -->
    </service>

All these ports described in details at [Network Configuration][network-guide] page of the official guide.

That's it. Now it should be visible in list of the services and you
can add it to your zone like this:

    firewall-cmd --zone=public --add-service=couchbase --permanent
    firewall-cmd --reload

[firewalld.service.xml]: https://git.fedorahosted.org/cgit/firewalld.git/tree/doc/xml/firewalld.service.xml
[network-guide]: http://developer.couchbase.com/documentation/server/current/install/install-ports.html
