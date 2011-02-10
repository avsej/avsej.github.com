---
layout: post
title: "Configure alternatives system for Oracle JDK of Fedora"
description: How to configure alternatives to easily switch between java versions
---

In Fedora linux and AFAIK in some others (like Debian) there is cool
system called `alternatives` which helps to install several versions
of software in the system and easily switch between them. As one
example for that might be installing different versions of
JDKs. Unfortunately Oracle JDK packages does not install alternatives
in its post-install hooks. This post mainly for future me to quickly
configure alternatives system correctly on Fedora.

Here I assume that Oracle RPMs downloaded and installed from
http://www.oracle.com/technetwork/java/javase/downloads/index.html

Now install `javac` links:

    alternatives \
      --install /usr/bin/javac javac /usr/java/latest/bin/javac 777 \
      --slave /usr/bin/java java /usr/java/latest/bin/java \
      --slave /usr/lib/jvm/java java_sdk /usr/java/latest \
      --slave /usr/bin/appletviewer appletviewer /usr/java/latest/bin/appletviewer \
      --slave /usr/bin/extcheck extcheck /usr/java/latest/bin/extcheck \
      --slave /usr/bin/idlj idlj /usr/java/latest/bin/idlj \
      --slave /usr/bin/jar jar /usr/java/latest/bin/jar \
      --slave /usr/bin/jarsigner jarsigner /usr/java/latest/bin/jarsigner \
      --slave /usr/bin/javadoc javadoc /usr/java/latest/bin/javadoc \
      --slave /usr/bin/javah javah /usr/java/latest/bin/javah \
      --slave /usr/bin/javap javap /usr/java/latest/bin/javap \
      --slave /usr/bin/jcmd jcmd /usr/java/latest/bin/jcmd \
      --slave /usr/bin/jconsole jconsole /usr/java/latest/bin/jconsole \
      --slave /usr/bin/jdb jdb /usr/java/latest/bin/jdb \
      --slave /usr/bin/jdeps jdeps /usr/java/latest/bin/jdeps \
      --slave /usr/bin/jhat jhat /usr/java/latest/bin/jhat \
      --slave /usr/bin/jinfo jinfo /usr/java/latest/bin/jinfo \
      --slave /usr/bin/jmap jmap /usr/java/latest/bin/jmap \
      --slave /usr/bin/jps jps /usr/java/latest/bin/jps \
      --slave /usr/bin/jrunscript jrunscript /usr/java/latest/bin/jrunscript \
      --slave /usr/bin/jsadebugd jsadebugd /usr/java/latest/bin/jsadebugd \
      --slave /usr/bin/jstack jstack /usr/java/latest/bin/jstack \
      --slave /usr/bin/jstat jstat /usr/java/latest/bin/jstat \
      --slave /usr/bin/jstatd jstatd /usr/java/latest/bin/jstatd \
      --slave /usr/bin/native2ascii native2ascii /usr/java/latest/bin/native2ascii \
      --slave /usr/bin/rmic rmic /usr/java/latest/bin/rmic \
      --slave /usr/bin/schemagen schemagen /usr/java/latest/bin/schemagen \
      --slave /usr/bin/serialver serialver /usr/java/latest/bin/serialver \
      --slave /usr/bin/wsgen wsgen /usr/java/latest/bin/wsgen \
      --slave /usr/bin/wsimport wsimport /usr/java/latest/bin/wsimport \
      --slave /usr/bin/xjc xjc /usr/java/latest/bin/xjc \
      --slave /usr/share/man/man1/appletviewer.1.gz appletviewer.1.gz /usr/java/latest/man/man1/appletviewer.1.gz \
      --slave /usr/share/man/man1/extcheck.1.gz extcheck.1.gz /usr/java/latest/man/man1/extcheck.1.gz \
      --slave /usr/share/man/man1/idlj.1.gz idlj.1.gz /usr/java/latest/man/man1/idlj.1.gz \
      --slave /usr/share/man/man1/jar.1.gz jar.1.gz /usr/java/latest/man/man1/jar.1.gz \
      --slave /usr/share/man/man1/jarsigner.1.gz jarsigner.1.gz /usr/java/latest/man/man1/jarsigner.1.gz \
      --slave /usr/share/man/man1/javac.1.gz javac.1.gz /usr/java/latest/man/man1/javac.1.gz \
      --slave /usr/share/man/man1/javadoc.1.gz javadoc.1.gz /usr/java/latest/man/man1/javadoc.1.gz \
      --slave /usr/share/man/man1/javah.1.gz javah.1.gz /usr/java/latest/man/man1/javah.1.gz \
      --slave /usr/share/man/man1/javap.1.gz javap.1.gz /usr/java/latest/man/man1/javap.1.gz \
      --slave /usr/share/man/man1/jcmd.1.gz jcmd.1.gz /usr/java/latest/man/man1/jcmd.1.gz \
      --slave /usr/share/man/man1/jconsole.1.gz jconsole.1.gz /usr/java/latest/man/man1/jconsole.1.gz \
      --slave /usr/share/man/man1/jdb.1.gz jdb.1.gz /usr/java/latest/man/man1/jdb.1.gz \
      --slave /usr/share/man/man1/jdeps.1.gz jdeps.1.gz /usr/java/latest/man/man1/jdeps.1.gz \
      --slave /usr/share/man/man1/jhat.1.gz jhat.1.gz /usr/java/latest/man/man1/jhat.1.gz \
      --slave /usr/share/man/man1/jinfo.1.gz jinfo.1.gz /usr/java/latest/man/man1/jinfo.1.gz \
      --slave /usr/share/man/man1/jmap.1.gz jmap.1.gz /usr/java/latest/man/man1/jmap.1.gz \
      --slave /usr/share/man/man1/jps.1.gz jps.1.gz /usr/java/latest/man/man1/jps.1.gz \
      --slave /usr/share/man/man1/jrunscript.1.gz jrunscript.1.gz /usr/java/latest/man/man1/jrunscript.1.gz \
      --slave /usr/share/man/man1/jsadebugd.1.gz jsadebugd.1.gz /usr/java/latest/man/man1/jsadebugd.1.gz \
      --slave /usr/share/man/man1/jstack.1.gz jstack.1.gz /usr/java/latest/man/man1/jstack.1.gz \
      --slave /usr/share/man/man1/jstat.1.gz jstat.1.gz /usr/java/latest/man/man1/jstat.1.gz \
      --slave /usr/share/man/man1/jstatd.1.gz jstatd.1.gz /usr/java/latest/man/man1/jstatd.1.gz \
      --slave /usr/share/man/man1/native2ascii.1.gz native2ascii.1.gz /usr/java/latest/man/man1/native2ascii.1.gz \
      --slave /usr/share/man/man1/policytool.1.gz policytool.1.gz /usr/java/latest/man/man1/policytool.1.gz \
      --slave /usr/share/man/man1/rmic.1.gz rmic.1.gz /usr/java/latest/man/man1/rmic.1.gz \
      --slave /usr/share/man/man1/schemagen.1.gz schemagen.1.gz /usr/java/latest/man/man1/schemagen.1.gz \
      --slave /usr/share/man/man1/serialver.1.gz serialver.1.gz /usr/java/latest/man/man1/serialver.1.gz \
      --slave /usr/share/man/man1/wsgen.1.gz wsgen.1.gz /usr/java/latest/man/man1/wsgen.1.gz \
      --slave /usr/share/man/man1/wsimport.1.gz wsimport.1.gz /usr/java/latest/man/man1/wsimport.1.gz \
      --slave /usr/share/man/man1/xjc.1.gz xjc.1.gz /usr/java/latest/man/man1/xjc.1.gz

Now `alternatives --config javac` should output something like this:

    # alternatives --config javac

    There are 3 programs which provide 'javac'.

    Selection    Command
    -----------------------------------------------
       1           /usr/lib/jvm/java-1.8.0-openjdk.x86_64/bin/javac
    *+ 2           /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.40-12.b02.fc22.x86_64/bin/javac
       3           /usr/java/latest/bin/javac

    Enter to keep the current selection[+], or type selection number:

And by selecting `3` Oracle JDK will become default in the system.
