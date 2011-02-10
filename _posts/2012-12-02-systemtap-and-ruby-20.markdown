---
layout: post
title: "SystemTap and ruby 2.0"
description: Showcase of SystemTap integration in ruby
---

As you might know already that the second preview of ruby 2.0
interpreter [has been released recently][1]. And there is dtrace support
among other cool features. I'm not fan of Solaris like others and use
just Debian GNU/Linux. But linux still has a tool which intended to solve
similar tasks: [SystemTap][2]. And it is possible to use it with
applications where dtrace support enabled as [said on their wiki][3]:

>   These calls are source compatible with dtrace on other platforms, so
>   the same source code compiled on a system that doesn't have
>   systemtap available, but does have a dtrace implementation will be
>   able to discover the same probe locations.

Let check if it is true for ruby.

## Setup

To use probepoints in ruby interpreter you should have a kernel with
UPROBES enabled:

    ~ $ grep  UPROBES /boot/config-*
    /boot/config-3.6-trunk-amd64:CONFIG_ARCH_SUPPORTS_UPROBES=y
    /boot/config-3.6-trunk-amd64:CONFIG_UPROBES=y

At this moment debian doesn't ship kernels with this option, but
building custom kernel isn't a complex task these days.

And of course SystemTap itself. I had an runtime compilation issue with
version from Debian repository (version 1.7-1+b1). The problem reported
as [Bug 14220][4] and fixed in [e14ac0e][5]. If you have similar issues,
just install recent stable version.

So given you have all prerequisites installed, just download and build
the ruby. It will automatically detect and configure SystemTap probes.
To verify installation, let just ask it to output all accessible probes:

    ~ $ stap -L 'process("/usr/local/bin/ruby").mark("*")'
    process("/usr/local/bin/ruby").mark("array__create") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("cmethod__entry") $arg1:long $arg2:long $arg3:long $arg4:long
    process("/usr/local/bin/ruby").mark("cmethod__return") $arg1:long $arg2:long $arg3:long $arg4:long
    process("/usr/local/bin/ruby").mark("find__require__entry") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("find__require__return") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("gc__mark__begin")
    process("/usr/local/bin/ruby").mark("gc__mark__end")
    process("/usr/local/bin/ruby").mark("gc__sweep__begin")
    process("/usr/local/bin/ruby").mark("gc__sweep__end")
    process("/usr/local/bin/ruby").mark("hash__create") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("load__entry") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("load__return") $arg1:long
    process("/usr/local/bin/ruby").mark("method__entry") $arg1:long $arg2:long $arg3:long $arg4:long
    process("/usr/local/bin/ruby").mark("method__return") $arg1:long $arg2:long $arg3:long $arg4:long
    process("/usr/local/bin/ruby").mark("object__create") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("parse__begin") $arg1:long $arg2:long
    process("/usr/local/bin/ruby").mark("parse__end") $arg1:long $arg2:long
    process("/usr/local/bin/ruby").mark("raise") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("require__entry") $arg1:long $arg2:long $arg3:long
    process("/usr/local/bin/ruby").mark("require__return") $arg1:long
    process("/usr/local/bin/ruby").mark("string__create") $arg1:long $arg2:long $arg3:long

Okay, looks like it does define some useful probepoints. Original
`probes.d` could be found in [ruby repository][6]. Lets see if we can
extract something useful.

## Counting 'require' in rails console

For example, determine how many files required when rails starts
console. To count all of then we will trace all points marked
`require__entry`. This is the simple script which does the job:

    global nmodules = 0;

    probe process("/usr/local/bin/ruby").mark("require__entry")
    {
        module = kernel_string($arg1)
        file = kernel_string($arg2)
        line = $arg3
        printf("%s(%d) %s %s:%d required file `%s'\n", execname(), pid(), $$name, file, line, module)
        nmodules++;
    }

    probe end {
        printf("Total files: %d\n", nmodules);
        delete nmodules;
    }

As you can see the script just outputs the required file name and the
place where `require` command was called. And then outputs total number
of the calls. The partial output ([full][7]):

    $ sudo stap rails-console-require.stp -c 'script/rails console'
    ruby(420) require__entry ruby:0 required file `enc/encdb.so'
    ruby(420) require__entry <internal:enc/prelude>:3 required file `enc/encdb.so'
    ruby(420) require__entry <internal:enc/prelude>:3 required file `enc/trans/transdb.so'
    ruby(420) require__entry <internal:gem_prelude>:1 required file `rubygems.rb'
    ... snip ...
    Total files: 966

## "top" for ruby functions

Another interesting example taken [from SystemTap wiki][8] and slightly
modified. It displays list of recent function calls for all ruby
processes in the system. It also refresh the list each seconds.

    global fn_calls;

    probe process("/usr/local/bin/ruby").mark("method__entry")
    {
        signature = sprintf("%s#%s", kernel_string($arg1), kernel_string($arg2))
        source = sprintf("%s:%d", kernel_string($arg3), $arg4)
        fn_calls[pid(), signature, source] <<< 1;
    }

    probe process("/usr/local/bin/ruby").mark("cmethod__entry")
    {
        signature = sprintf("%s.%s", kernel_string($arg1), kernel_string($arg2))
        source = sprintf("%s:%d", kernel_string($arg3), $arg4)
        fn_calls[pid(), signature, source] <<< 1;
    }

    probe timer.ms(1000) {
        ansi_clear_screen()
        printf("%-6s %-6s %-30s %-40s\n",
                "PID", "CALLS", "FUNCTION", "FILENAME")
        foreach ([pid, signature, source] in fn_calls- limit 20) {
            printf("%-6d %-6d %-40s %-80s\n",
                    pid, @count(fn_calls[pid, signature, source]),
                    signature, source);
        }
        delete fn_calls;
    }

The script collects stats and every seconds draw them in the table. In
this form it might be not very useful, but it is easy to modify the
script for your needs. Here is the sample output. I'm running with
option `-DMAXMAPENTRIES=10000` to extend the size of `fn_calls` map.

    $ sudo stap -DMAXMAPENTRIES=10000 rubytop.stp
    PID    CALLS  FUNCTION                           FILENAME
    3900   29598  IO.write                           /usr/local/lib/ruby/2.0.0/irb/ext/save-history.rb:92
    4468   14799  String.chomp                       /usr/local/lib/ruby/2.0.0/irb/ext/save-history.rb:79
    4468   2223   Module.===                         /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1725
    4468   2106   BasicObject.==                     /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1725
    4468   2106   Kernel.===                         /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1725
    4468   837    File.file?                         /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1371
    4468   780    Gem::Specification#default_value   /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1437
    4468   780    Symbol.to_s                        /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1729
    4468   780    Kernel.instance_variable_set       /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1729
    4468   702    Kernel.initialize_dup              /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1726
    4468   702    Kernel.dup                         /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1726
    4468   468    Array.initialize_copy              /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1726
    4468   390    Kernel.instance_variable_set       /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1719
    4468   390    Symbol.to_s                        /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1719
    4468   309    Gem#suffixes                       /usr/local/lib/ruby/2.0.0/rubygems.rb:837
    4468   289    Hash.[]=                           /usr/local/lib/ruby/2.0.0/rubygems.rb:962
    4468   282    RbConfig#expand                    /usr/local/lib/ruby/2.0.0/x86_64-linux/rbconfig.rb:221
    4468   282    String.gsub                        /usr/local/lib/ruby/2.0.0/x86_64-linux/rbconfig.rb:222
    4468   279    Enumerable.any?                    /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1371
    4468   279    Array.each                         /usr/local/lib/ruby/2.0.0/rubygems/specification.rb:1371

## Conclusion

This post shows only the tip of the iceberg. I really recommend you to
take a look at SystemTap, because it is very powerful tool which might
tell you a lot about your system and application you are running. Also
note that using dtrace/SystemTap doesn't introduce a lot of overhead in
the binary, therefore you can inspect your production deployments too.

More links:

* [SystemTap comparison to other tools][9]
* [SystemTap usage stories and interesting demos][10]

[1]: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/50443
[2]: http://sourceware.org/systemtap/
[3]: http://sourceware.org/systemtap/wiki/AddingUserSpaceProbingToApps#Compiled-in_instrumentation
[4]: http://sourceware.org/bugzilla/show_bug.cgi?id=14220
[5]: http://sourceware.org/git/gitweb.cgi?p=systemtap.git;a=commitdiff;h=e14ac0e
[6]: https://github.com/ruby/ruby/blob/v2_0_0_preview2/probes.d
[7]: //avsej.net/rails-console.txt
[8]: http://sourceware.org/systemtap/wiki/RubyMarker?action=AttachFile&do=view&target=rubyfuntop.stp
[9]: http://sourceware.org/systemtap/wiki/SystemtapDtraceComparison
[10]: http://sourceware.org/systemtap/wiki/WarStories
