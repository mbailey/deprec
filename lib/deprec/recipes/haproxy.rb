# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :haproxy do
      
      SRC_PACKAGES[:haproxy] = {
        :md5sum => "0d6019b79631048765a7dfd55f1875cd  haproxy-1.4.0.tar.gz",
        :url => "http://haproxy.1wt.eu/download/1.4/src/haproxy-1.4.0.tar.gz",
        :configure => '',
        :make => "TARGET=linux26"

      }
      
      desc "Install haproxy"
      task :install, :roles => :haproxy do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:haproxy], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:haproxy], src_dir)
        config
        activate
        create_check_file
      end

      # default config expects this file in web root
      task :create_check_file, :roles => :haproxy do
        sudo "test -d /var/www && #{sudo} touch /var/www/check.txt"
      end
      
      task :install_deps, :roles => :haproxy do
        apt.install( {:base => %w(build-essential)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:haproxy] = [
        
        {:template => "haproxy.cfg.erb",
         :path => '/etc/haproxy.cfg',
         :mode => 0644,
         :owner => 'root:root'},
        
        {:template => "haproxy-init.d",
         :path => '/etc/init.d/haproxy',
         :mode => 0755,
         :owner => 'root:root'}
         
      ]

      PROJECT_CONFIG_FILES[:haproxy] = [
        
        # {:template => "example.conf.erb",
        #  :path => 'conf/example.conf',
        #  :mode => 0755,
        #  :owner => 'root:root'}
      ]
      
      desc "Generate configuration files for haproxy from template(s)"
      task :config_gen do
        config_gen_system
        config_gen_project
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:haproxy].each do |file|
          deprec2.render_template(:haproxy, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:haproxy].each do |file|
          deprec2.render_template(:haproxy, file)
        end
      end
      
      desc 'Deploy configuration filess for haproxy' 
      task :config, :roles => :haproxy do
        config_system
        # config_project
        reload
      end

      task :config_system, :roles => :haproxy do
        deprec2.push_configs(:haproxy, SYSTEM_CONFIG_FILES[:haproxy])
      end

      task :config_project, :roles => :haproxy do
        deprec2.push_configs(:haproxy, PROJECT_CONFIG_FILES[:haproxy])
      end
      
      
      task :start, :roles => :haproxy do
        run "#{sudo} /etc/init.d/haproxy start"
      end
      
      task :stop, :roles => :haproxy do
        run "#{sudo} /etc/init.d/haproxy stop"
      end
      
      task :restart, :roles => :haproxy do
        run "#{sudo} /etc/init.d/haproxy restart"
      end
      
      task :reload, :roles => :haproxy do
        run "#{sudo} /etc/init.d/haproxy reload"
      end
      
      task :activate, :roles => :haproxy do
        run "#{sudo} update-rc.d haproxy defaults"
      end  
      
      task :deactivate, :roles => :haproxy do
        run "#{sudo} update-rc.d -f haproxy remove"
      end
      
    end
  end
end
