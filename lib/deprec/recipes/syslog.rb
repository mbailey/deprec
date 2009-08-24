# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :syslog do
      
      set(:syslog_server) { Capistrano::CLI.ui.ask 'Enter Syslog server hostname' }

      desc "Install syslog"
      task :install do
        install_deps
      end

      # install dependencies for sysklogd
      task :install_deps do
        apt.install( {:base => %w(sysklogd)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:syslog] =  [
        
       { :template => 'syslog.conf.erb',
         :path => '/etc/syslog.conf',
         :mode => 0644,
         :owner => 'root:root'},

       { :template => 'syslogd.erb',
         :path => '/etc/default/syslogd',
         :mode => 0644,
         :owner => 'root:root'}
         
      ]
           
      desc "Generate Syslog configs"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:syslog].each do |file|
         deprec2.render_template(:syslog, file)
        end
      end

      desc "Push Syslog config files to server"
      task :config, :roles => :all_hosts, :except => {:syslog_master => true} do
        deprec2.push_configs(:syslog, SYSTEM_CONFIG_FILES[:syslog])
        restart
      end

      desc "Start Syslog"
      task :start, :roles => :all_hosts, :except => { :syslog_master => true } do
        run "#{sudo} /etc/init.d/sysklogd start"
      end
      
      desc "Stop Syslog"
      task :stop, :roles => :all_hosts, :except => { :syslog_master => true } do
        run "#{sudo} /etc/init.d/sysklogd stop"
      end
      
      desc "Restart Syslog"
      task :restart, :roles => :all_hosts, :except => { :syslog_master => true } do
        run "#{sudo} /etc/init.d/sysklogd restart"
      end

    end 
    
  end
end
