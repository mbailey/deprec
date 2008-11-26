# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :passenger do
      
      set :passenger_install_dir, '/opt/passenger'
      set(:passenger_document_root) { "#{deploy_to}/public" }
      set :passenger_rails_allow_mod_rewrite, 'off'
      set :passenger_vhost_dir, '/etc/apache2/sites-enabled'
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
        :version => 'release-2.0.3', # Specify a tagged release to deploy
        :configure => '',
        :make => '',
        :install => './bin/passenger-install-apache2-module'
      }
      
      SYSTEM_CONFIG_FILES[:passenger] = [

        {:template => 'passenger.erb',
          :path => '/etc/apache2/conf.d/passenger',
          :mode => 0755,
          :owner => 'root:root'}

      ]

      PROJECT_CONFIG_FILES[:passenger] = [

        { :template => 'apache_vhost.erb',
          :path => 'apache_vhost',
          :mode => 0755,
          :owner => 'root:root'}

      ]

      desc "Install passenger"
      task :install, :roles => :passenger do
        # install_deps
        deprec2.download_src(SRC_PACKAGES[:passenger], src_dir)

        # Non standard - passenger requires input
        package_dir = File.join(src_dir, 'passenger.git')
        dest_dir = passenger_install_dir + '-' + (SRC_PACKAGES[:passenger][:version] || 'trunk')
        run "#{sudo} rsync -avz #{package_dir}/ #{dest_dir}"
        run <<-EOF
        cd #{dest_dir} &&
        #{sudo} ruby -i -pe '$_ = $_.sub("STDIN.readline","# do nothing")' bin/passenger-install-apache2-module
        EOF
        run "cd #{dest_dir} && #{sudo} ./bin/passenger-install-apache2-module"
        run "#{sudo} unlink #{passenger_install_dir} 2>/dev/null; #{sudo} ln -sf #{dest_dir} #{passenger_install_dir}"
      end

      # install dependencies for nginx
      task :install_deps, :roles => :passenger do
        apt.install( {:base => %w(apache2-mpm-prefork apache2-prefork-dev rsync)}, :stable )
      end
       
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
      task :config, :roles => :passenger do
        config_system
        config_project  
      end

      desc "Push Passenger configs (system level) to server"
      task :config_system, :roles => :passenger do
        deprec2.push_configs(:passenger, SYSTEM_CONFIG_FILES[:passenger])
      end

      desc "Push Passenger configs (project level) to server"
      task :config_project, :roles => :passenger do
        deprec2.push_configs(:passenger, PROJECT_CONFIG_FILES[:passenger])
        symlink_passenger_vhost
      end

      task :symlink_passenger_vhost, :roles => :passenger do
        sudo "ln -sf #{deploy_to}/passenger/apache_vhost #{passenger_vhost_dir}/#{application}"
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