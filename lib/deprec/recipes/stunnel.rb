# Copyright 2006-2010 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :stunnel do
            
      desc "Install stunnel"
      task :install do
        install_deps
        config
      end
      
      task :install_deps do
        apt.install( {:base => %w(stunnel ssl-cert)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:stunnel] = [
        
        {:template => 'stunnel.conf-client',
        :path => '/etc/stunnel/stunnel.conf',
        :mode => 0644,
        :owner => 'root:root'},

        {:template => 'stunnel4',
        :path => '/etc/defaults/stunnel4',
        :mode => 0644,
        :owner => 'root:root'}
        
      ]

      task :config_gen do
        SYSTEM_CONFIG_FILES[:stunnel].each do |file|
          deprec2.render_template(:stunnel, file)
        end
      end

      desc "Push stunnel config files to server"
      task :config do
        deprec2.push_configs(:stunnel, SYSTEM_CONFIG_FILES[:stunnel])
        restart
      end

      desc "Restart stunnel"
      task :restart do
        run "#{sudo} /etc/init.d/stunnel4 reload"
      end

    end
    
  end
end
