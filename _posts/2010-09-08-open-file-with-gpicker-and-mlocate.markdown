---
layout: post
title: Open file with gpicker and mlocate
description: Yet another use case for great tool gpicker. Pick files from locate database
---

[gpicker][1] is a convenient tool for selecting files. Yesterday I remembered that it supports the gathering of data from the [mlocate][2] database and decided  to setup a convenient opening files from the mlocate database using gpicker and `gnome-open`. To start you need to know where the base mlocate in your system. The path can be found on the man page [`locate(1)`][3] or via a call `locate -h`:

    $ locate -h | grep "\.db"
          /var/lib/mlocate/mlocate.db)

This is enough to bring all together:

    $ gnome-open `gpicker -t mlocate --eat-prefix="" /var/lib/mlocate/mlocate.db`

Option `--eat-prefix` means strip prefix to make paths relative.

It remains only to set up a hotkey in metacity (e.g. via [gconftool-2(1)][4]):

    $ gconftool-2 --search-key-regex run_command_\\d+
      /apps/metacity/global_keybindings/run_command_1 = <Super>c
      /apps/metacity/global_keybindings/run_command_2 = <Super>f
      /apps/metacity/global_keybindings/run_command_3 = <Super>s
      /apps/metacity/global_keybindings/run_command_4 = <Super>x
      /apps/metacity/global_keybindings/run_command_5 = <Super>d
      /apps/metacity/global_keybindings/run_command_6 = <Super>v
      /apps/metacity/global_keybindings/run_command_7 = <Super>a
      /apps/metacity/global_keybindings/run_command_8 = disabled
      /apps/metacity/global_keybindings/run_command_10 = disabled
      /apps/metacity/global_keybindings/run_command_11 = disabled
      /apps/metacity/global_keybindings/run_command_12 = disabled
      /apps/metacity/global_keybindings/run_command_9 = disabled

Choose free number and assign it to the command and hot-key.

    $ gconftool-2 --type string --set /apps/metacity/global_keybindings/run_command_10 '<Super>g'
    $ gconftool-2 --type string --set /apps/metacity/keybinding_commands/command_10 'sh -c "gnome-open `gpicker -t mlocate --eat-prefix="" /var/lib/mlocate/mlocate.db`"'

![Pick files with gpicker, mlocate and gnome-open](//avsej.net/assets/gpicker-mlocate.png)

Also you can create local mlocate database for particular directory:

    $ updatedb -o mlocate.db -U .
    $ gpicker -t mlocate mlocate.db

To use mlocate you need to install gpicker 2.1 ([tarball][5], [deb-i386][6], [deb-amd64][7])

Links
------

1. [gpicker repository](//github.com/alk/gpicker)
2. [gpicker releases](http://download.savannah.gnu.org/releases/gpicker)

[1]: //github.com/alk/gpicker
[2]: http://carolina.mff.cuni.cz/~trmac/blog/mlocate
[3]: http://linux.die.net/man/1/locate
[4]: http://linux.die.net/man/1/gconftool-2
[5]: http://download.savannah.gnu.org/releases/gpicker/gpicker-2.1.tar.gz
[6]: http://download.savannah.gnu.org/releases/gpicker/gpicker_2.1-1_i386.deb
[7]: http://download.savannah.gnu.org/releases/gpicker/gpicker_2.1-1_amd64.deb
