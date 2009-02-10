# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  require 'digest'
  
  set :wpmu_root, '/var/www/wpmu'
  set(:wpmu_domain) { Capistrano::CLI.ui.ask 'Enter domain wordpress will be served on' }  
  
  namespace :deprec do 
    namespace :wpmu do
          
      SRC_PACKAGES[:wpmu] =
        {
        :url => "http://mu.wordpress.org/latest.tar.gz",
        :dir => 'wordpress-mu'
        }
      
      desc "Install Wordpress"
      task :install, :roles => :wpmu do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:wpmu], src_dir)
        deprec2.unpack_src(SRC_PACKAGES[:wpmu], src_dir)
        sudo "test -d #{wpmu_root} && #{sudo} rm -fr #{wpmu_root}; exit 0;"
        sudo "mv #{src_dir}/wordpress-mu #{wpmu_root}"
        initial_config
        sudo "a2ensite wpmu"
        top.deprec.apache.reload
      end
      
      task :manual_instructions do
        puts <<-DESC
        
  Run something like the following mysql commands on your datbase server: 

    drop database wpmu;
    create database wpmu;
    grant all on wpmu.* to 'wpmu'@'%' identified by 'wpmu';
    flush privileges;
  
  Then run:

    cap deprec:wpmu:make_insecure

  Setup database access via the webpage at: 

    http://#{wpmu_domain}/

  Then run: 

    cap deprec:wpmu:make_secure
        
        DESC
      end
      
      task :install_deps, :roles => :wpmu do
        top.deprec.apache.install
        sudo "a2enmod rewrite"
        top.deprec.php.install
      end
      
      PROJECT_CONFIG_FILES[:wpmu] = [
         
        {:template => "apache_vhost.conf.erb",
         :path => '/etc/apache2/sites-available/wpmu',
         :mode => 0755,
         :owner => 'root:root'}
         
      ]
      
      desc "Generate configuration file(s) for wpmu from template(s)"
      task :config_gen do
        PROJECT_CONFIG_FILES[:wpmu].each do |file|
           deprec2.render_template(:wpmu, file)
         end
      end
      
      desc "Push wordpress config files to server"
      task :config, :roles => :wpmu do
        deprec2.push_configs(:wpmu, SYSTEM_CONFIG_FILES[:wpmu])
      end
      
      # Push direct to remote
      task :initial_config, :roles => :wpmu do
        PROJECT_CONFIG_FILES[:wpmu].each do |file|
           deprec2.render_template(:wpmu, file.merge(:remote => true))
         end
      end
      
      # Set permissions to allow wpmu to write config files
      task :make_insecure, :roles => :wpmu do
        sudo "chmod 777 #{wpmu_root} #{wpmu_root}/wp-content"
      end
      
      # Reverse the previous command
      task :make_secure, :roles => :wpmu do
        sudo "chmod 755 #{wpmu_root} #{wpmu_root}/wp-content"
      end
      
    end
  end
  
end
