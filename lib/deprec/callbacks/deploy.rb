# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy:setup',       'deprec:deploy:chown'
  after 'deploy:update_code', 'deprec:deploy:symlink_database_yml'
  after 'deploy:update_code', 'deprec:deploy:symlink_backups'
end
