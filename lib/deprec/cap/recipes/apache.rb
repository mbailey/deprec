# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :apache do
      
      set :apache_user, 'www-data'
      set :apache_log_dir, '/var/log/apache2'
      set :apache_vhost_dir, '/etc/apache2/sites-available'
      set :apache_ssl_enabled, false
      set :apache_ssl_ip, nil
      set :apache_ssl_forward_all, apache_ssl_enabled
      set :apache_ssl_chainfile, false
      set :apache_modules_enabled, 
        %w(rewrite ssl proxy_balancer proxy_http deflate expires headers)

      desc "Install Apache"
      task :install do
        apt.install( 
          {:base => %w(apache2-mpm-prefork apache2-prefork-dev rsync ssl-cert)},
          :stable )
        config
      end
      
      SYSTEM_CONFIG_FILES[:apache] = [
        
        { :template => 'apache2.conf.erb',
          :path => '/etc/apache2/apache2.conf',
          :mode => 0644,
          :owner => 'root:root'},

        { :template => 'namevirtualhosts.conf',
          :path => '/etc/apache2/conf.d/namevirtualhosts.conf',
          :mode => 0644,
          :owner => 'root:root'},
          
        { :template => 'ports.conf.erb',
          :path => '/etc/apache2/ports.conf',
          :mode => 0644,
          :owner => 'root:root'},

        { :template => 'status.conf.erb',
          :path => '/etc/apache2/mods-available/status.conf',
          :mode => 0644,
          :owner => 'root:root'},

        { :template => 'default.erb',
          :path => '/etc/apache2/sites-available/default',
          :mode => 0644,
          :owner => 'root:root'}
          
      ]

      PROJECT_CONFIG_FILES[:apache] = [
        # Not required
      ]

      desc "Generate Apache config files"
      task :config_gen do
        config_gen_system
      end

      # Generate system level apache configs
      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end

      # Not used here
      task :config_gen_project do
      end
      
      desc "Push Apache config files to server"
      task :config, :roles => :web do
        config_system
        enable_modules
        reload
      end
      
      desc "Push Apache config files to server"
      task :config_system, :roles => :web do
        deprec2.push_configs(:apache, SYSTEM_CONFIG_FILES[:apache])
        run "#{sudo} touch /var/www/check.txt" # Used to test webserver up
      end
      
      # Stub so generic tasks don't fail (e.g. deprec:web:config_project)
      task :config_project do
        # XXX Need to flesh out generation of custom certs
        # In the meantime we'll just use the snakeoil cert
        #
        top.deprec.ssl.config if apache_ssl_enabled
      end

      task :enable_modules, :roles => :web do
        apache_modules_enabled.each { |mod| sudo "a2enmod #{mod}" }
      end

      #
      # Control
      #
      
      desc "Start Apache"
      task :start, :roles => :web do
        run "#{sudo} /etc/init.d/apache2 start"
      end

      desc "Stop Apache"
      task :stop, :roles => :web do
        run "#{sudo} /etc/init.d/apache2 stop"
      end

      desc "Restart Apache"
      task :restart, :roles => :web do
        run "#{sudo} /etc/init.d/apache2 restart"
      end

      desc "Reload Apache"
      task :reload, :roles => :web do
        run "#{sudo} /etc/init.d/apache2 force-reload"
      end

      desc "Set Apache to start on boot"
      task :activate, :roles => :web do
        run "#{sudo} update-rc.d apache2 defaults"
      end
      
      desc "Set Apache to not start on boot"
      task :deactivate, :roles => :web do
        run "#{sudo} update-rc.d -f apache2 remove"
      end
      
      # Apache vhost extras
      #
      # These are only used for generating vhost files with: 
      #
      #   cap deprec:apache:vhost
      #
      set(:apache_vhost_domain) { Capistrano::CLI.ui.ask 'Primary domain' }
      set(:apache_vhost_server_alii) { 
        Capistrano::CLI.ui.ask('ServerAlii (space separated)' ).split(' ')
      }
      set :apache_vhost_access_log_type, 'combined'
      set :apache_vhost_canonicalize_hostname, true
      set(:apache_vhost_access_log) { 
        File.join(apache_log_dir, "#{apache_vhost_domain}-access.log")
      }
      set(:apache_vhost_error_log) { 
        File.join(apache_log_dir, "#{apache_vhost_domain}-error.log")
      }
      set(:apache_vhost_document_root) { 
        File.join('/var/apps', "#{apache_vhost_domain}", 'public')
      }
      set :apache_vhost_rack_env, false
      # 
      task :vhost do
        file = { 
          :template => 'vhost.erb',
          :path => "/etc/apache2/sites-available/#{apache_vhost_domain}",
          :mode => 0644,
          :owner => 'root:root'
        }
        if ! File.exists? 'config'
          file[:path] = "../../#{apache_vhost_domain}"
        end    
        deprec2.render_template(:apache, file)
      end
      
      # End apache vhost extras
    end
  end
end
