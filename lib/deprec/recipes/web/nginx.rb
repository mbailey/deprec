# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :nginx do

      set :nginx_server_name, nil
      set :nginx_user,  'nginx'
      set :nginx_group, 'nginx'
      set :nginx_vhost_dir, '/usr/local/nginx/conf/vhosts'
      set :nginx_client_max_body_size, '100M'
      set :nginx_worker_processes, 4

      SRC_PACKAGES[:nginx] = {
        :url => "http://nginx.org/download/nginx-0.8.54.tar.gz",
        :md5sum => "44df4eb6a22d725021288c570789046f  nginx-0.8.54.tar.gz",
        :configure => './configure --sbin-path=/usr/local/sbin --with-http_ssl_module;'
      }

      desc "Install nginx"
      task :install, :roles => :web do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:nginx], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nginx], src_dir)
        create_nginx_user
        initial_config
        activate
        start
      end

      # install dependencies for nginx
      task :install_deps, :roles => :web do
        apt.install( {:base => %w(libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlib1g-dev)}, :stable )
        # do we need libgcrypt11-dev?
      end

      task :create_nginx_user, :roles => :web do
        deprec2.groupadd(nginx_group)
        deprec2.useradd(nginx_user, :group => nginx_group, :homedir => false)
      end

      SYSTEM_CONFIG_FILES[:nginx] = [

        {:template => 'nginx-init-script',
          :path => '/etc/init.d/nginx',
          :mode => 0755,
          :owner => 'root:root'},

        {:template => 'nginx.conf.erb',
          :path => "/usr/local/nginx/conf/nginx.conf",
          :mode => 0644,
          :owner => 'root:root'},

        {:template => 'mime.types.erb',
          :path => "/usr/local/nginx/conf/mime.types",
          :mode => 0644,
          :owner => 'root:root'},

        {:template => 'nothing.conf',
          :path => "/usr/local/nginx/conf/vhosts/nothing.conf",
          :mode => 0644,
          :owner => 'root:root'}
      ]
      
      PROJECT_CONFIG_FILES[:nginx] = [
           
        {:template => 'logrotate.conf.erb',
         :path => "logrotate.conf", 
         :mode => 0644,
         :owner => 'root:root'}  
      ]

      task :initial_config, :roles => :web do
        SYSTEM_CONFIG_FILES[:nginx].each do |file|
          deprec2.render_template(:nginx, file.merge(:remote => true))
        end
      end
      
      desc <<-DESC
      Generate nginx config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        SYSTEM_CONFIG_FILES[:nginx].each do |file|
          deprec2.render_template(:nginx, file)
        end
      end
      
      desc "Generate config files for rails app."
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:nginx].each do |file|
          deprec2.render_template(:nginx, file)
        end
      end

      desc "Push nginx config files to server"
      task :config, :roles => :web do
        deprec2.push_configs(:nginx, SYSTEM_CONFIG_FILES[:nginx])
      end
      
      desc "Push out config files for rails app."
      task :config_project, :roles => :web do
        deprec2.push_configs(:nginx, PROJECT_CONFIG_FILES[:nginx])
      end

      desc <<-DESC
      Activate nginx start scripts on server.
      Setup server to start nginx on boot.
      DESC
      task :activate, :roles => :web do
        activate_system
      end

      task :activate_system, :roles => :web do
        send(run_method, "update-rc.d nginx defaults")
      end

      desc <<-DESC
      Dectivate nginx start scripts on server.
      Setup server to start nginx on boot.
      DESC
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f nginx remove")
      end

      # Control

      desc "Start Nginx"
      task :start, :roles => :web do
        # Nginx returns error code if you try to start it when it's already running
        # We don't want this to kill Capistrano.
        send(run_method, "/etc/init.d/nginx start; exit 0")
      end

      desc "Stop Nginx"
      task :stop, :roles => :web do
        # Nginx returns error code if you try to stop when it's not running
        # We don't want this to kill Capistrano. 
        send(run_method, "/etc/init.d/nginx stop; exit 0") 
      end

      desc "Restart Nginx"
      task :restart, :roles => :web do
        stop
        start
      end

      desc "Reload Nginx"
      task :reload, :roles => :web do
        # Nginx returns error code if you try to reload when it's not running
        # We don't want this to kill Capistrano.
        send(run_method, "/etc/init.d/nginx reload; exit 0")
      end

      task :backup, :roles => :web do
        # there's nothing to backup for nginx
      end

      task :restore, :roles => :web do
        # there's nothing to store for nginx
      end
      
      # Helper task to get rid of pesky "it works" page - not called by deprec tasks
      task :rename_index_page, :roles => :web do
        index_file = '/usr/local/nginx/html/index.html'
        sudo "test -f #{index_file} && sudo mv #{index_file} #{index_file}.orig || exit 0"
      end

    end 
  end
end
