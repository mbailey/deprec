deprec - Deployment Recipes for Capistrano
==========================================

The [deprec][1] gem is a set of tasks for [Capistrano][2]. These tasks provide
for the installation, configuration and control of system services on servers
running Ubuntu linux. Deprec was created in 2006 by Mike Bailey to setup an
environment for running Ruby on Rails web applications on Ubuntu servers. Since
then its uses have grown to installing Xen virtualization, mail, monitoring, 
high availability IP failover and other services.

The tasks are run at the command line on your workstation and connect to 
remote servers via ssh to run commands and copy out files.

Deprec-2.x is a complete rewrite of the project that achieves the following:

* support for Capistrano 2
* generated config files are stored locally to enable editing and version control
* support for more services (heartbeat, nagios, nginx, ntp, postfix, etc) 
* multiple Rails deployment options (Passenger+Apache, Mongrel+Apache/Nginx)
* creation of a standard base set of task names
* tasks are cleanly separated into namespaced units (one file per service)
* interactive prompting for missing config values

Deprec and Capistrano are written in the [Ruby programming language][3] however 
no knowledge of Ruby is required to use it. Users should be able to write 
new tasks and modify existing options without prior knowledge of Ruby.


Installation
------------

Deprec can using rubygems[5].

	sudo gem install deprec  # installs deprec and dependancies 
	depify -c                # creates ~/.caprc which you may edit
	cap -T                   # should list lots of deprec tasks

The .caprc file is loaded every time you use Capistrano. It in turn loads 
the deprec tasks so you always have them available. Editing the .caprc file 
in your home directory allows you to specify the location of your ssh key
and enable some other useful options (documented in the comments). You can
also put tasks here that you want access to, regardless of the current working
directory.


Installing other things
-----------------------

I plan to document other things I use deprec for on http://www.deprec.org/. 
Feel free to poke around and see what's there. I use deprec to provision and 
manage servers so you might find some things in there I haven't documented. Lucky you.


Disclaimer
----------

The tasks run commands that may make changes to your workstation and remote server. 
You are advised to read the source and use at your own risk.


Credits
-------

Deprec is written and maintained by Mike Bailey <mike@bailey.net.au>. 
More about me here: [http://mike.bailey.net.au/]

Deprec was inspired and uses the brilliantly executed Capistrano. Thanks Jamis!
This gem includes a modified copy of Neil Wilson's very useful vmbuilder_plugins gem.


Thanks
------

Deprec wouldn't be what it is without the contributions of many people, a few of whom are listed here:

  Square Circle Triangle: commissioned work that has included in the project.
  Eric Harris-Braun: great testing, bug reports and suggestions
  Gus Gollings: helped restore www.deprec.org
  Craig Ambrose: testing, documentation and beer

  github forks of note:
    isaac
    paulreimer
    jasherai
    saimonmoore
    zippy


License
-------

Deprec is licenced under the GPL. This means that you can use it in commercial 
or open source applications. More details found here:
http://www.gnu.org/licenses/gpl.html

deprec - deployment recipes for capistrano
Copyright (C) 2006-2008 Mike Bailey

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


[1]: http://www.deprec.org/
[2]: http://www.capify.org/
[3]: http://www.ruby-lang.org/en/
[4]: http://rubyforge.org/
[5]: http://rubygems.org/
[6]: http://www.sct.com.au/
