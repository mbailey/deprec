after 'deploy:setup', 'deprec:deploy:chown'
after 'deploy:update_code', 'deprec:deploy:symlink_database_yml'
after 'deploy:update_code', 'symlink_backups'
