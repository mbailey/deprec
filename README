------------------------------------------
deprec - Deployment Recipes for Capistrano
------------------------------------------

== Introduction

The deprec [1] gem is a set of tasks for Capistrano [2]. These tasks provide
for the installation, configuration and control of system services. Deprec 
was created in 2006 by Mike Bailey to setup an environment for running Ruby 
on Rails web applications on Ubuntu dapper servers. Since then its uses have
grown to installing mail, monitoring, high availability IP failover and other 
services.

The tasks are run at the command line on your workstation and connect to 
remote servers via ssh to run commands and copy out files.

Deprec-2.x is a complete rewrite of the project that achieves the following:

- support for Capistrano 2
- support for more services (heartbeat, nagios, nginx, ntp, postfix, etc) 
- creation of a standard base set of task names
- tasks are cleanly separated into namespaced units (one file per service)
- service config files are stored locally to enable edits and version control
- interactive prompting for missing config values

One idea that is in the trash can is supporting other distros/OS's. While I got
caught up in the excitement of The Big Rewrite I've decided I don't need it. If 
you want to deploy to something other than Ubuntu I suggest you look for other 
alternatives.

Deprec and Capistrano are written in the Ruby programming language [3] however 
no knowledge of Ruby is required to use it. Users should be able to write 
new tasks and modify existing options without prior knowledge of Ruby.


== Installation

Deprec can be obtained from rubyforge[4] and installed using rubygems[5].

	sudo gem install deprec  # installs deprec and dependancies 
	cap depify .			 # creates ~/.caprc which you may edit
	cap -T					 # should list lots of deprec tasks

The .caprc file is loaded every time you use Capistrano. It in turn loads 
the deprec tasks so you always have them available. Editing the .caprc file 
in your home directory allows you to specify the location of your ssh key
and enable some other useful options (documented in the comments). You can
also put tasks here that you want to always have access to.


== Getting a Ruby on Rails app running on a fresh Ubuntu server

This is still what brings people to deprec. You can install a full Rails stack
and get multiple apps running on it in much less time than it would take to 
do it manually. Think an hour vs. a weekend. (The irony is I'm up writing this
on a Saturday night.)

	export HOSTS=<target.host.name>

	# Install Rails stack
	cap deprec:rails:install_rails_stack

	# Install mysql (if it's running on the same box)
	cap deprec:mysql:install
	cap deprec:mysql:config_gen
	cap deprec:mysql:config

	# Install your Rails app
	cap deploy:setup
	cap deploy
	cap deprec:db:create
	cap deprec:db:migrate
	cap deprec:nginx:restart
	cap deprec:mongrel:restart

You can find documentation on the deprec site. http://www.deprec.org/


== Installing other things

I plan to document other things I use deprec for on http://www.deprec.org/. 
Feel free to poke around and see what's there. I use deprec to provision and 
manage servers so you might find some things in there I haven't documented. Lucky you.


== Disclaimer

The tasks run commands that may make changes to your workstation and remote server. 
You are advised to read the source and use at your own risk.


== Credits

Deprec is written and maintained by Mike Bailey <mike@bailey.net.au>. 
More about me here: [http://mike.bailey.net.au/]

Deprec was inspired and uses the brilliantly executed Capistrano. Thanks Jamis!
This gem includes a modified copy of Neil Wilson's very useful vmbuilder_plugins gem.


== Thanks

Eric Harris-Braun: great testing, bug reports and suggestions
Gus Gollings: helped restore www.deprec.org
Craig Ambrose: testing, documentation and beer


== License

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


[1] http://www.deprec.org
[2] http://www.capify.org
[3] http://www.ruby-lang.org/en/
[4] http://rubyforge.org/
[5] http://rubygems.org/