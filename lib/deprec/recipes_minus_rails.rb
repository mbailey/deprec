# Copyright 2006-2008 by Mike Bailey. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end
require "#{File.dirname(__FILE__)}/recipes/canonical"
require "#{File.dirname(__FILE__)}/recipes/deprec"
require "#{File.dirname(__FILE__)}/recipes/deprecated"

# Updated for deprec3

require "#{File.dirname(__FILE__)}/recipes/users"
require "#{File.dirname(__FILE__)}/recipes/network"
require "#{File.dirname(__FILE__)}/recipes/mri"
require "#{File.dirname(__FILE__)}/recipes/ree"
require "#{File.dirname(__FILE__)}/recipes/rack"
require "#{File.dirname(__FILE__)}/recipes/rubygems"
require "#{File.dirname(__FILE__)}/recipes/nagios3"
require "#{File.dirname(__FILE__)}/recipes/nrpe"
require "#{File.dirname(__FILE__)}/recipes/git"
require "#{File.dirname(__FILE__)}/recipes/svn"

# To be updated for deprec3

require "#{File.dirname(__FILE__)}/recipes/ssh"
require "#{File.dirname(__FILE__)}/recipes/passenger"
require "#{File.dirname(__FILE__)}/recipes/mysql"
require "#{File.dirname(__FILE__)}/recipes/postgresql"
require "#{File.dirname(__FILE__)}/recipes/apache"
require "#{File.dirname(__FILE__)}/recipes/haproxy"
require "#{File.dirname(__FILE__)}/recipes/heartbeat"
require "#{File.dirname(__FILE__)}/recipes/monit"
require "#{File.dirname(__FILE__)}/recipes/collectd"
require "#{File.dirname(__FILE__)}/recipes/ubuntu"

# To be decided...

require "#{File.dirname(__FILE__)}/recipes/ec2"
require "#{File.dirname(__FILE__)}/recipes/vmware_tools"
require "#{File.dirname(__FILE__)}/recipes/mongrel"
require "#{File.dirname(__FILE__)}/recipes/sqlite"
require "#{File.dirname(__FILE__)}/recipes/nginx"
require "#{File.dirname(__FILE__)}/recipes/bash"
require "#{File.dirname(__FILE__)}/recipes/php"
require "#{File.dirname(__FILE__)}/recipes/aoe"
require "#{File.dirname(__FILE__)}/recipes/ddclient"
require "#{File.dirname(__FILE__)}/recipes/ntp"
require "#{File.dirname(__FILE__)}/recipes/logrotate"
require "#{File.dirname(__FILE__)}/recipes/ssl"
require "#{File.dirname(__FILE__)}/recipes/postfix"
require "#{File.dirname(__FILE__)}/recipes/memcache"
require "#{File.dirname(__FILE__)}/recipes/syslog"
require "#{File.dirname(__FILE__)}/recipes/syslog_ng"
require "#{File.dirname(__FILE__)}/recipes/stunnel"
require "#{File.dirname(__FILE__)}/recipes/lvm"
require "#{File.dirname(__FILE__)}/recipes/vnstat"
require "#{File.dirname(__FILE__)}/recipes/utils"


require "#{File.dirname(__FILE__)}/recipes/erlang"

# Retired recipes
#
# require "#{File.dirname(__FILE__)}/recipes/integrity"
# require "#{File.dirname(__FILE__)}/recipes/xen"
# require "#{File.dirname(__FILE__)}/recipes/xentools"
# require "#{File.dirname(__FILE__)}/recipes/scm/trac"
# require "#{File.dirname(__FILE__)}/recipes/sphinx"
# require "#{File.dirname(__FILE__)}/recipes/apt_mirror"
# require "#{File.dirname(__FILE__)}/recipes/wpmu"
# require "#{File.dirname(__FILE__)}/recipes/ar_sendmail"
# require "#{File.dirname(__FILE__)}/recipes/starling"
# require "#{File.dirname(__FILE__)}/recipes/couchdb"
