# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :apache do
      
      # put apache config for site in shared/config/apache2 dir
      # link it into apps to enable, unlink to disable? 
      # http://times.usefulinc.com/2006/09/15-rails-debian-apache
      
      # XXX Check this over after a nice sleep
      #
      # def set_apache_conf
      #   if apache_default_vhost
      #     set :apache_conf, "/usr/local/apache2/conf/default.conf" unless apache_default_vhost_conf
      #   else 
      #     set :apache_conf, "/usr/local/apache2/conf/apps/#{application}.conf" unless apache_conf
      #   end
      # end
        
      set(:apache_server_name) { domain }
      set :apache_user, 'daemon' # XXX this is not yet being inserted into httpd.conf!
                                 # I've added it for deprec:nagios:install
      set :apache_conf, nil
      set :apache_default_vhost, false
      set :apache_default_vhost_conf, nil
      set :apache_ctl, "/usr/local/apache2/bin/apachectl"
      set(:apache_server_aliases) { web_server_aliases }
      set :apache_proxy_port, 8000
      set :apache_proxy_servers, 2
      set :apache_proxy_address, "127.0.0.1"
      set :apache_ssl_enabled, false
      set :apache_ssl_ip, nil
      set :apache_ssl_forward_all, false
      set :apache_ssl_chainfile, false
      set :apache_docroot, '/usr/local/apache2/htdocs'
      set :apache_vhost_dir, '/usr/local/apache2/conf/apps'
      set :apache_config_file, '/usr/local/apache2/conf/httpd.conf'
      
      SRC_PACKAGES[:apache] = {
        :filename => 'httpd-2.2.6.tar.gz',   
        :md5sum => "d050a49bd7532ec21c6bb593b3473a5d  httpd-2.2.6.tar.gz", 
        :dir => 'httpd-2.2.6',  
        :url => "http://www.apache.org/dist/httpd/httpd-2.2.6.tar.gz",
        :unpack => "tar zxf httpd-2.2.6.tar.gz;",
        :configure => %w(
          ./configure
          --enable-mods-shared=all
          --enable-proxy 
          --enable-proxy-balancer 
          --enable-proxy-http 
          --enable-rewrite  
          --enable-cache 
          --enable-headers 
          --enable-ssl 
          --enable-deflate 
          --with-included-apr   #_so_this_recipe_doesn't_break_when_rerun
          --enable-dav          #_for_subversion_
          --enable-so           #_for_subversion_
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;',
        :post_install => 'install -b support/apachectl /etc/init.d/httpd;'
      }
      
      desc "Install apache"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:apache], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:apache], src_dir)
        setup_vhost_dir
        install_index_page
      end
      
      # install dependencies for apache
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev zlib1g openssl libssl-dev)}, :stable )
      end
      
      # Create dir for vhost config files
      task :setup_vhost_dir do
        deprec2.mkdir(apache_vhost_dir, :owner => 'root', :group => group, :mode => 0775, :via => :sudo)
        deprec2.append_to_file_if_missing(apache_config_file, 'Include conf/apps/')
      end
      
      SYSTEM_CONFIG_FILES[:apache] = [
        # They're generated and put in place during install
        # I may put them in here at some point
      ]

      PROJECT_CONFIG_FILES[:apache] = [
        
        {:template => "httpd-vhost-app.conf.erb",
         :path => 'conf/httpd-vhost-app.conf',
         :mode => 0755,
         :owner => 'root:root'}
      ]

      desc "Generate configuration file(s) for apache from template(s)"
      task :config_gen do
        config_gen_system
        config_gen_project
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end
      
      desc "Push apache config files to server"
      task :config, :roles => :web do
        config_system
        config_project
      end

      task :config_system, :roles => :web do
        deprec2.push_configs(:apache, SYSTEM_CONFIG_FILES[:apache])
      end

      task :config_project, :roles => :web do
        deprec2.push_configs(:apache, PROJECT_CONFIG_FILES[:apache])
        sudo "ln -sf #{deploy_to}/apache/conf/httpd-vhost-app.conf /usr/local/apache2/conf/apps/#{application}.conf"        
      end

      desc "Start Apache"
      task :start, :roles => :web do
        send(run_method, "#{apache_ctl} start")
      end

      desc "Stop Apache"
      task :stop, :roles => :web do
        send(run_method, "#{apache_ctl} stop")
      end

      desc "Restart Apache"
      task :restart, :roles => :web do
        send(run_method, "#{apache_ctl} restart")
      end

      desc "Reload Apache"
      task :reload, :roles => :web do
        send(run_method, "#{apache_ctl} reload")
      end

      desc "Set apache to start on boot"
      task :activate, :roles => :web do
        send(run_method, "update-rc.d httpd defaults")
      end
      
      desc "Set apache to not start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f httpd remove")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end

      # Generate an index.html page  
      task :install_index_page, :roles => :web do
        deprec2.mkdir(apache_docroot, :owner => :root, :group => :deploy, :mode => 0775, :via => :sudo)
        std.su_put deprec2.render_template(:apache, :template => 'index.html.erb'), File.join(apache_docroot, 'index.html')
        std.su_put deprec2.render_template(:apache, :template => 'master.css'), File.join(apache_docroot, 'master.css')
      end
      
    end
  end
end