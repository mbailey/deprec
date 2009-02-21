# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  require 'digest'
  
  default :application,  'wordpress'
  set(:wordpress_domain) { Capistrano::CLI.ui.ask 'Enter domain wordpress will be served on' }
  set :db_name,     'wordpress'
  set :db_user,     'wordpress'
  set(:db_pass)     { Capistrano::CLI.ui.ask 'Enter db password for wordpress' }
  set(:db_host)     { Capistrano::CLI.ui.ask 'Enter db hostname for wordpress' }
  set :db_charset,  'utf8'
  set :db_collate,  ''
  
  set(:auth_key)        { Digest::SHA1.hexdigest srand.to_s }
  set(:secure_auth_key) { Digest::SHA1.hexdigest srand.to_s }
  set(:logged_in_key)   { Digest::SHA1.hexdigest srand.to_s }
  
  set(:wordpress_install_dir) { "#{deploy_to}/public" }
  
  
  namespace :deprec do 
    namespace :wordpress do
          
      SRC_PACKAGES[:wordpress] =
        {
        :url => "http://wordpress.org/latest.tar.gz",
        :dir => 'wordpress'
        }
      
      desc "Install Wordpress"
      task :install do
        install_deps unless ENV['SKIP_DEPS'] # save time by skipping deps (when reinstalling) 
        deprec2.download_src(SRC_PACKAGES[:wordpress], src_dir)
        deprec2.unpack_src(SRC_PACKAGES[:wordpress], src_dir)
        deprec2.mkdir wordpress_install_dir, :via => :sudo
        sudo "cp -r #{src_dir}/wordpress/* #{wordpress_install_dir}/"
      end
      
      task :install_deps do
        top.deprec.apache.install
        top.deprec.php.install
      end
      
      PROJECT_CONFIG_FILES[:wordpress] = [
        
        {:template => "wp-config.php.erb",
         :path => 'wp-config.php',
         :mode => 0755,
         :owner => 'root:root'},
         
        {:template => "apache2_wordpress_vhost.conf.erb",
         :path => 'apache2_wordpress_vhost.conf',
         :mode => 0755,
         :owner => 'root:root'}
         
      ]
      
      desc "Generate configuration file(s) for mongrel from template(s)"
      task :config_gen do
        config_gen_project
      end
      
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:wordpress].each do |file|
          deprec2.render_template(:wordpress, file)
        end  
      end
      
      desc "Push wordpress config files to server"
      task :config, :roles => :wordpress do
        config_project
      end
      
      task :config_project, :roles => :wordpress do
        deprec2.push_configs(:wordpress, PROJECT_CONFIG_FILES[:wordpress])
        sudo "ln -sf #{deploy_to}/wordpress/wp-config.php #{wordpress_install_dir}/wp-config.php"
        sudo "ln -sf #{deploy_to}/wordpress/apache2_wordpress_vhost.conf #{apache_vhost_dir}/#{application}.conf"        
      end
      
      desc <<-EOF
        Create a database for WordPress on your web server, as well as 
        a MySQL user who has all privileges for accessing and modifying it.
      EOF
      task :create_database, :roles => lambda { db_host } do
        run <<-EOF
          mysql -u root -e 'create database #{DB_NAME}'
          mysql -u root -e 'grant all on #{DB_NAME}.* to '#{DB_USER}'@'%' identified by '#{DB_PASSWORD}'
          mysql -u root -e 'flush privileges'
        EOF
      end
      
    end
  end
  
end
