# Copyright 2006-2011 by Mike Bailey. All rights reserved.
require 'deprec-core'
Capistrano::Configuration.instance(:must_exist).load do
  require 'deprec/recipes/deploy'
  after 'deploy:setup',       'deprec:deploy:chown'
  after 'deploy:update_code', 'deprec:deploy:symlink_database_yml'
  after 'deploy:update_code', 'deprec:deploy:symlink_backups'
end
