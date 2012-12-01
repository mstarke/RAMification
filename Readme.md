# RAMification

A Tool to manage RAM disks.

## ATTENTION

This is a small pet project and in no way finished. I'm working on it on a very irregular basis and the current code if far from complete.

## Features

Not all Features are implemented yet.

### Core Freatures

* create, mount and unmount a default RAM disk
* optionally disable Unified Media Buffer on RAM disks to reduce memory footprint
* autolaunch on login

### Favourite Management

* create, mount and unmount favourites
* manage favourites (volume name, size, backup mode, automount on launch)
* automount favourites
* autosync favourites (backup on unmount, restore on mount, etc. )
* autoresize favourites
* autorename favourites based on file system activity
* block unmounting of favourites without (configured) backups
* customize icons for each ramdisk

## Disclaimer

The tool is in heavy development and may very well not work at all or break things on your machine. Use at your own risk.

## Contribution

If you feel like adding things or commenting on the development directions feel free to contact me.

## License

RAMification RAMdisk Utility
Copyright &copy; 2012 [HicknHack Software GmbH](http://www.hicknhack-software.com) michael.starke@hicknhack-software.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.

## Credits
This Tool makes use of the following software
[LaunchAtLoginController](https://github.com/Mozketo/LaunchAtLoginController#readme) by Ben Clark-Robinson licensed under the MIT License
[VDKQueue](https://github.com/bdkjones/VDKQueue) &copy; 2012 Bryan D K Jones based on [UKKQueue](http://zathras.de/sourcecode.htm#UKKQueue) &copy; 2003 Uli Kusterer
