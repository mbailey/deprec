require 'digest/sha1'

# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :integrity do
      
      set :integrity_install_dir, '/opt/apps/integrity'
      set(:integrity_domain) do
        Capistrano::CLI.ui.ask 'Please enter domain name' do |q| 
          q.default = 'integrity.failmode.com'
        end
      end
      set :integrity_use_basic_auth, true
      set :integrity_hash_admin_password, true
      set(:integrity_admin_username) do
         Capistrano::CLI.ui.ask 'Please enter admin username' do |q| 
           q.default = 'admin'
         end
       end
      set(:integrity_admin_password) { Capistrano::CLI.password_prompt 'Please enter admin password' }
      set :integrity_user, 'integrity'
      
      
      desc "Install Integrity"
      task :install, :roles => :ci do
        install_deps        
        sudo 'gem sources -a http://gems.github.com'
        gem2.install 'integrity'
        
        sudo "integrity install --passenger #{integrity_install_dir}"
        deprec2.useradd 'integrity'
        sudo "chown -R #{integrity_user} #{integrity_install_dir}"
      end

      # Install dependencies for Integrity
      task :install_deps, :roles => :ci do
        apt.install( {:base => %w(postfix sqlite3 libsqlite3-dev git libxslt1-dev libxml2-dev)}, :stable )
        gem2.install 'sqlite3-ruby'
        gem2.install 'do_sqlite3'
        # Gems your tests might need
        gem2.install 'webrat'
      end
      
      SYSTEM_CONFIG_FILES[:integrity] = [

        { :template => 'apache_vhost.erb',
          :path => "/etc/apache2/sites-available/integrity",
          :mode => 0755,
          :owner => 'root:root'},
          
       { :template => 'config.ru.erb',
         :path => "/opt/apps/integrity/config.ru", # XXX shouldn't be hard coded
         :mode => 0755,
         :owner => 'root:root'},
            
       { :template => 'config.yml.erb',
         :path => "/opt/apps/integrity/config.yml", # XXX shouldn't be hard coded
         :mode => 0755,
         :owner => 'root:root'}

      ]
       
      desc "Generate Integrity apache configs (system & project level)."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:integrity].each do |file|
          deprec2.render_template(:integrity, file)
        end
      end

      desc "Push Integrity config files (system & project level) to server"
      task :config, :roles => :ci do
        deprec2.push_configs(:integrity, SYSTEM_CONFIG_FILES[:integrity])
        sudo "chown #{integrity_user} #{integrity_install_dir}/config.ru"
        activate
      end
      
      # XXX Setup database for testing project
      #
      # $ mysql -uroot p
      #  mysql> CREATE USER integrity INDENTIFIED BY PASSWORD 'mypassword123';
      #  mysql> CREATE DATABASE my_cool_application_test;
      #  mysql> GRANT ALL ON my_cool_application_test.* TO 'integrity'@localhost IDENTIFIED BY 'mypassword123';
      
      task :activate, :roles => :ci do
        sudo "a2ensite integrity"
        restart_apache
      end
      
      task :deactivate, :roles => :ci do
        sudo "a2dissite integrity"
        restart_apache
      end
      
      desc "Restart Application"
      task :restart, :roles => :ci do
        sudo "touch #{integrity_install_dir}/tmp/restart.txt"
      end
      
      desc "Restart Apache"
      task :restart_apache, :roles => :ci do
        run "#{sudo} /etc/init.d/apache2 restart"
      end
      
    end
    
  end
end
