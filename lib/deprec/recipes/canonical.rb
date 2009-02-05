# Copyright 2006-2008 by Mike Bailey. All rights reserved.
# canonical.rb
#
# Running deprec:web:stop will be the same as running deprec:apache:stop or 
# deprec:nginx:stop depending what you have chosen.
#
# generic namespaces are linked up to chosen applications at runtime but these
# stubs are so they'll be included in the output of "cap -T"
#
Capistrano::Configuration.instance(:must_exist).load do 
  
  %w(ruby).each do |package|
    namespace "deprec:#{package}" do
      
      desc "Install #{package.capitalize}"
      task :install do 
      end
      
    end
  end
  
  %w(web app db).each do |server|
    namespace "deprec:#{server}" do
      
      desc "Install #{server.capitalize} server"
      task :install, :roles => server do 
      end
      
      desc "Generate config file(s) for #{server} server from template(s)"
      task :config_gen do
      end
      
      desc "Deploy configuration files(s) for #{server} server"
      task :config, :roles => server do
      end
      
      desc "Start #{server} server"
      task :start, :roles => server do
      end
      
      desc "Stop #{server} server"
      task :stop, :roles => server do
      end
      
      desc "Stop #{server} server"
      task :restart, :roles => server do
      end
      
      desc "Enable startup script for #{server} server"
      task :activate, :roles => server do
      end  
      
      desc "Disable startup script for #{server} server"
      task :deactivate, :roles => server do
      end
      
      desc "Backup data for #{server} server"
      task :backup, :roles => server do
      end
      
      desc "Restore data for #{server} server from backup"
      task :restore, :roles => server do
      end
      
    end
  end
  
end