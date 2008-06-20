# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :logrotate do

      # Install      

      desc "Install logrotate"
      task :install do
        install_deps
      end

      # install dependencies for nginx
      task :install_deps do
        apt.install( {:base => %w(logrotate)}, :stable )
      end

      # Configure

      SYSTEM_CONFIG_FILES[:logrotate] = [

        {:template => 'logrotate.conf.erb',
          :path => '/etc/logrotate.conf',
          :mode => 0755,
          :owner => 'root:root'}
      ]

      desc "Generate logrotate config from template."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:logrotate].each do |file|
          deprec2.render_template(:logrotate, file)
        end
      end

      desc "Push logrotate config files to server"
      task :config do
        deprec2.push_configs(:logrotate, SYSTEM_CONFIG_FILES[:logrotate])
      end

      # Control
      #
      # logrotate is run via cron with a script in /etc/cron.daily/logrotate 
      
      desc "Force logrotate to run"
      task :force do
        sudo "logrotate -f /etc/logrotate.conf"
      end

    end 
  end
end
