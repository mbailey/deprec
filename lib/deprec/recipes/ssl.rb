# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :ssl do

      # Install Openssl
      task :install, :roles => :web do
        install_deps
      end

      # Install dependencies for ssl
      task :install_deps, :roles => :web do
        apt.install( {:base => %w(openssl)}, :stable )
      end

      PROJECT_CONFIG_FILES[:ssl] = [

        {:template => 'ssl-cert-snakeoil.pem',
          :path => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
          :mode => 0644,
          :owner => 'root:root'},

        {:template => 'ssl-cert-snakeoil.key',
          :path => "/etc/ssl/private/ssl-cert-snakeoil.key",
          :mode => 0640,
          :owner => 'root:ssl-cert'},
          
        { :template => 'make-ssl-cert',
            :path => "/usr/sbin/make-ssl-cert",
            :mode => 0755,
            :owner => 'root:root'}
          
      ]
      
      # Generate ssl certs
      task :config_gen do
        PROJECT_CONFIG_FILES[:ssl].each do |file|
          deprec2.render_template(:ssl, file)
        end
      end

      # Copy out ssl certs
      task :config, :roles => :web do
        deprec2.push_configs(:ssl, PROJECT_CONFIG_FILES[:ssl])
      end
      
    end
    
  end
end
      
