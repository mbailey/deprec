# Copyright 2006-2008 by Mike Bailey. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end
require "#{File.dirname(__FILE__)}/cap/recipes/canonical"
require "#{File.dirname(__FILE__)}/cap/recipes/deprec"
require "#{File.dirname(__FILE__)}/cap/recipes/deprecated"

# Updated for deprec3

require "#{File.dirname(__FILE__)}/cap/recipes/users"
require "#{File.dirname(__FILE__)}/cap/recipes/network"
require "#{File.dirname(__FILE__)}/cap/recipes/mri"
require "#{File.dirname(__FILE__)}/cap/recipes/ree"
require "#{File.dirname(__FILE__)}/cap/recipes/rack"
require "#{File.dirname(__FILE__)}/cap/recipes/rubygems"
require "#{File.dirname(__FILE__)}/cap/recipes/nagios3"
require "#{File.dirname(__FILE__)}/cap/recipes/nrpe"
require "#{File.dirname(__FILE__)}/cap/recipes/git"

# To be updated for deprec3

require "#{File.dirname(__FILE__)}/cap/recipes/ssh"
require "#{File.dirname(__FILE__)}/cap/recipes/passenger"
require "#{File.dirname(__FILE__)}/cap/recipes/mysql"
require "#{File.dirname(__FILE__)}/cap/recipes/postgresql"
require "#{File.dirname(__FILE__)}/cap/recipes/apache"
require "#{File.dirname(__FILE__)}/cap/recipes/haproxy"
require "#{File.dirname(__FILE__)}/cap/recipes/heartbeat"
require "#{File.dirname(__FILE__)}/cap/recipes/monit"
require "#{File.dirname(__FILE__)}/cap/recipes/collectd"
require "#{File.dirname(__FILE__)}/cap/recipes/ubuntu"

# To be decided...

require "#{File.dirname(__FILE__)}/cap/recipes/ec2"
require "#{File.dirname(__FILE__)}/cap/recipes/mongrel"
require "#{File.dirname(__FILE__)}/cap/recipes/sqlite"
require "#{File.dirname(__FILE__)}/cap/recipes/nginx"
require "#{File.dirname(__FILE__)}/cap/recipes/bash"
require "#{File.dirname(__FILE__)}/cap/recipes/php"
require "#{File.dirname(__FILE__)}/cap/recipes/aoe"
require "#{File.dirname(__FILE__)}/cap/recipes/lvm"
require "#{File.dirname(__FILE__)}/cap/recipes/ntp"
require "#{File.dirname(__FILE__)}/cap/recipes/logrotate"
require "#{File.dirname(__FILE__)}/cap/recipes/ssl"
require "#{File.dirname(__FILE__)}/cap/recipes/postfix"
require "#{File.dirname(__FILE__)}/cap/recipes/syslog"
require "#{File.dirname(__FILE__)}/cap/recipes/syslog_ng"
require "#{File.dirname(__FILE__)}/cap/recipes/stunnel"
require "#{File.dirname(__FILE__)}/cap/recipes/utils"
