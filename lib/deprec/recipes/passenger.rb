# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :passenger do

      set :passenger_version, '3.0.7'    
      set(:passenger_root) { capture("passenger-config --root").chomp }
      set(:passenger_ruby) { capture("which ruby").chomp }

      # Default settings for Passenger config files
      set(:passenger_document_root) { "#{current_path}/public" }
      set :passenger_rails_allow_mod_rewrite, 'off'
      set :passenger_log_level, 0
      set(:passenger_log_dir) { "#{shared_path}/log"} 
      set :passenger_user_switching, 'on'
      set :passenger_default_user, 'nobody'
      set :passenger_max_pool_size, 6
      set :passenger_max_instances_per_app, 0
      set :passenger_pool_idle_time, 300
      set :passenger_rails_autodetect, 'on'
      set :passenger_rails_spawn_method, 'smart' # smart | conservative
      set :passenger_redirect_to_canonical_hostname, true
      set(:passenger_server_alii) {
        if domain =~ /^www\./
          domain.sub 'www.', ''
        else
          "www.#{domain}"
        end
      }

      desc "Install Passenger"
      task :install, :roles => :app do
        install_deps
        gem2.install 'passenger', passenger_version
        run "#{sudo} passenger-install-apache2-module _#{passenger_version}_ --auto"
        config_system
      end
      
      # Install dependencies for Passenger
      task :install_deps, :roles => :app do
        apt.install( {:base => %w(libcurl4-openssl-dev apache2-mpm-prefork apache2-prefork-dev libapr1-dev libaprutil1-dev rsync)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:passenger] = [

        {:template => 'passenger.load.erb',
          :path => '/etc/apache2/mods-available/passenger.load',
          :mode => 0755,
          :owner => 'root:root'},
          
        {:template => 'passenger.conf.erb',
          :path => '/etc/apache2/mods-available/passenger.conf',
          :mode => 0755,
          :owner => 'root:root'}

      ]

      PROJECT_CONFIG_FILES[:passenger] = [

        { :template => 'apache_vhost.erb',
          :path => "apache_vhost",
          :mode => 0755,
          :owner => 'root:root'},
          
        {:template => 'logrotate.conf.erb',
         :path => "logrotate.conf", 
         :mode => 0644,
         :owner => 'root:root'}

      ]
       
      desc "Generate Passenger apache configs (system & project level)."
      task :config_gen do
        # config_gen_system 
        config_gen_project
      end

      # desc "Generate Passenger apache configs (system level) from template."
      # We can't generate passenger configs because we need to contact remote system 
      # to find out gem location & ruby version.
      task :config_gen_system do
        puts "We don't generate local Passenger system files"
        # SYSTEM_CONFIG_FILES[:passenger].each do |file|
        #   deprec2.render_template(:passenger, file)
        # end
      end

      desc "Generate Passenger apache configs (project level) from template."
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file)
        end
      end

      desc "Push Passenger config files (system & project level) to server"
      task :config, :roles => :app do
        config_system
        config_project  
      end

      desc "Push Passenger configs (system level) to server"
      task :config_system, :roles => :app do
        deprec2.push_configs(:passenger, SYSTEM_CONFIG_FILES[:passenger])
        activate_system
      end

      desc "Push Passenger configs (project level) to server"
      task :config_project, :roles => :app do
        deprec2.push_configs(:passenger, PROJECT_CONFIG_FILES[:passenger])
        symlink_apache_vhost
        activate_project
        symlink_logrotate_config
      end
      
      task :symlink_logrotate_config, :roles => :app do
        sudo "ln -sf #{deploy_to}/passenger/logrotate.conf /etc/logrotate.d/passenger-#{application}"
      end
      
      # Passenger runs Rails as the owner of this file.
      task :set_owner_of_environment_rb, :roles => :app do
        sudo "chown #{app_user} #{current_path}/config/environment.rb"
      end
      
      task :symlink_apache_vhost, :roles => :app do
        sudo "ln -sf #{deploy_to}/passenger/apache_vhost #{apache_vhost_dir}/#{application}"
      end
      
      task :activate, :roles => :app do
        activate_system
        activate_project
      end
      
      task :activate_system, :roles => :app do
        sudo "a2enmod passenger"
        top.deprec.web.reload
      end
      
      task :activate_project, :roles => :app do
        sudo "a2ensite #{application}"
        top.deprec.web.reload
      end
      
      task :deactivate do
        puts
        puts "******************************************************************"
        puts
        puts "Danger!"
        puts
        puts "Do you want to deactivate just this project or all Passenger"
        puts "projects on this server? Try a more granular command:"
        puts
        puts "cap deprec:passenger:deactivate_system  # disable Passenger"
        puts "cap deprec:passenger:deactivate_project # disable only this project"
        puts
        puts "******************************************************************"
        puts
      end
      
      task :deactivate_system, :roles => :app do
        sudo "a2dismod passenger"
        top.deprec.web.reload
      end
      
      task :deactivate_project, :roles => :app do
        sudo "a2dissite #{application}"
        top.deprec.web.reload
      end
      
      desc "Restart Application"
      task :restart, :roles => :app do
        run "#{sudo} touch #{current_path}/tmp/restart.txt"
      end
      
      desc "Restart Apache"
      task :restart_apache, :roles => :passenger do
        run "#{sudo} /etc/init.d/apache2 restart"
      end
      
    end
    
  end
end
