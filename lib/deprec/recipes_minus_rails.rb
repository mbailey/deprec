# Copyright 2006-2008 by Mike Bailey. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

# Don't load the rails recipes in ~/.caprc
#
# This excludes the 'before' and 'after' tasks deprec adds to 
# facilitate rails setup.
#
#require "#{File.dirname(__FILE__)}/recipes/rails"

require "#{File.dirname(__FILE__)}/recipes/canonical"
require "#{File.dirname(__FILE__)}/recipes/deprec"
require "#{File.dirname(__FILE__)}/recipes/deprecated"

require "#{File.dirname(__FILE__)}/recipes/app/mongrel"
require "#{File.dirname(__FILE__)}/recipes/app/passenger"
require "#{File.dirname(__FILE__)}/recipes/db/mysql"
require "#{File.dirname(__FILE__)}/recipes/db/postgresql"
require "#{File.dirname(__FILE__)}/recipes/db/sqlite"
require "#{File.dirname(__FILE__)}/recipes/ruby/mri"
require "#{File.dirname(__FILE__)}/recipes/ruby/ree"
require "#{File.dirname(__FILE__)}/recipes/web/apache"
require "#{File.dirname(__FILE__)}/recipes/web/nginx"

require "#{File.dirname(__FILE__)}/recipes/git"
require "#{File.dirname(__FILE__)}/recipes/gitosis"
require "#{File.dirname(__FILE__)}/recipes/svn"

require "#{File.dirname(__FILE__)}/recipes/users"
require "#{File.dirname(__FILE__)}/recipes/ssh"
require "#{File.dirname(__FILE__)}/recipes/php"
# require "#{File.dirname(__FILE__)}/recipes/scm/trac"

require "#{File.dirname(__FILE__)}/recipes/aoe"

require "#{File.dirname(__FILE__)}/recipes/xen"
require "#{File.dirname(__FILE__)}/recipes/xentools"

require "#{File.dirname(__FILE__)}/recipes/ddclient"
require "#{File.dirname(__FILE__)}/recipes/ntp"
require "#{File.dirname(__FILE__)}/recipes/logrotate"
require "#{File.dirname(__FILE__)}/recipes/ssl"

require "#{File.dirname(__FILE__)}/recipes/postfix"
require "#{File.dirname(__FILE__)}/recipes/memcache"
require "#{File.dirname(__FILE__)}/recipes/monit"
require "#{File.dirname(__FILE__)}/recipes/network"
require "#{File.dirname(__FILE__)}/recipes/nagios"
require "#{File.dirname(__FILE__)}/recipes/heartbeat"

require "#{File.dirname(__FILE__)}/recipes/ubuntu"
require "#{File.dirname(__FILE__)}/recipes/lvm"
require "#{File.dirname(__FILE__)}/recipes/vnstat"
require "#{File.dirname(__FILE__)}/recipes/sphinx"
require "#{File.dirname(__FILE__)}/recipes/utils"
require "#{File.dirname(__FILE__)}/recipes/apt_mirror"
# require "#{File.dirname(__FILE__)}/recipes/wordpress" Not working
require "#{File.dirname(__FILE__)}/recipes/wpmu"
require "#{File.dirname(__FILE__)}/recipes/ar_sendmail"
require "#{File.dirname(__FILE__)}/recipes/starling"
