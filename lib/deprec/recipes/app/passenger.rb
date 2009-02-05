# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :passenger do
          
      set(:passenger_install_dir) { 
        if ruby_vm_type == :ree
          "#{ree_install_dir}/lib/ruby/gems/1.8/gems/passenger-2.0.6"
        else
          '/opt/passenger'
        end
      }
      
      set(:passenger_document_root) { "#{current_path}/public" }
      set :passenger_rails_allow_mod_rewrite, 'off'
      # Default settings for Passenger config files
      set :passenger_log_level, 0
      set :passenger_user_switching, 'on'
      set :passenger_default_user, 'nobody'
      set :passenger_max_pool_size, 6
      set :passenger_max_instances_per_app, 0
      set :passenger_pool_idle_time, 300
      set :passenger_rails_autodetect, 'on'
      set :passenger_rails_spawn_method, 'smart' # smart | conservative

      SRC_PACKAGES[:passenger] = {
        :url => "git://github.com/FooBarWidget/passenger.git",
        :download_method => :git,
        :version => 'release-2.0.6', # Specify a tagged release to deploy
        :configure => '',
        :make => '',
        :install => './bin/passenger-install-apache2-module'
      }

      desc "Install passenger"
      task :install, :roles => :app do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:passenger], src_dir)

        if ruby_vm_type.to_s == 'ree'
          # Install the Passenger that came with Ruby Enterprise Edition
          run "yes | #{sudo} env PATH=#{ree_install_dir}/bin:$PATH #{ree_install_dir}/bin/passenger-install-apache2-module"
        else
          # Non standard - passenger requires input
          package_dir = File.join(src_dir, 'passenger.git')
          dest_dir = passenger_install_dir + '-' + (SRC_PACKAGES[:passenger][:version] || 'trunk')
          run "#{sudo} rsync -avz #{package_dir}/ #{dest_dir}"
          run "cd #{dest_dir} && yes '' | #{sudo} ./bin/passenger-install-apache2-module"
          run "#{sudo} unlink #{passenger_install_dir} 2>/dev/null; #{sudo} ln -sf #{dest_dir} #{passenger_install_dir}"
        end
        
        initial_config_push
        
      end
      
      task :initial_config_push, :roles => :web do
        # XXX Non-standard!
        # We need to push out the .load and .conf files for Passenger
        SYSTEM_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file.merge(:remote => true))
        end
      end

      # Install dependencies for Passenger
      task :install_deps, :roles => :app do
        apt.install( {:base => %w(apache2-mpm-prefork apache2-prefork-dev rsync)}, :stable )
        gem2.install 'fastthread'
        gem2.install 'rack'
        gem2.install 'rake'
        # These are more Rails than Passenger - Mike
        # gem2.install 'rails'
        # gem2.install "mysql -- --with-mysql-config='/usr/bin/mysql_config'"
        # gem2.install 'sqlite3-ruby'
        # gem2.install 'postgres'
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
          :owner => 'root:root'}

      ]
       
      desc "Generate Passenger apache configs (system & project level)."
      task :config_gen do
        config_gen_system 
        config_gen_project
      end

      desc "Generate Passenger apache configs (system level) from template."
      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:passenger].each do |file|
          deprec2.render_template(:passenger, file)
        end
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
        run "touch #{current_path}/tmp/restart.txt"
      end
      
      desc "Restart Apache"
      task :restart_apache, :roles => :passenger do
        run "#{sudo} /etc/init.d/apache2 restart"
      end
      
    end
    
  end
end