# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :php do
      
      desc "Install PHP"
      task :install do
        install_deps
      end
      
      # Install dependencies for php
      task :install_deps do
        apt.install( {:base => %w(php5 php5-mysql)}, :stable )
      end
      
      desc "generate config file for php"
      task :config_gen do
        # not yet implemented
      end
      
      desc "deploy config file for php" 
      task :config, :roles => :web do
        # not yet implemented
      end
      
      task :start, :roles => :web do
        # not applicable
      end
      
      task :stop, :roles => :web do
        # not applicable
      end
      
      task :restart, :roles => :web do
        # not applicable
      end
      
      desc "enable php in webserver"
      task :activate, :roles => :web do
        # not yet implemented
      end  
      
      desc "disable php in webserver"
      task :deactivate, :roles => :web do
        # not yet implemented
      end
      
      task :backup, :roles => :web do
        # not applicable
      end
      
      task :restore, :roles => :web do
        # not applicable
      end
      
    end
  end
end