# Copyright 2006-2010 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :syslog_ng do

      set(:syslog_ng_loghost_name) { 
        Capistrano::CLI.ui.ask "Loghost address" do |q|
          q.default = ''
        end
      }
      set :syslog_ng_loghost_port, 514

      desc "Setup server"
      task :server_setup do
        install_deps
        deprec2.render_template(
          :syslog_ng, 
          :template => 'syslog-ng.conf-server',
          :path => '/etc/syslog-ng/syslog-ng.conf',
          :mode => 0644,
          :owner => 'root:root',
          :remote => true
        )
        restart
      end
            
      desc "Install syslog-ng"
      task :install do
        syslog_ng_loghost_name # get user input at beginning
        install_deps
        config
      end
      
      task :install_deps do
        apt.install( {:base => %w(syslog-ng)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:syslog_ng] = [
        
        {:template => 'syslog-ng.conf-client',
        :path => '/etc/syslog-ng/syslog-ng.conf',
        :mode => 0644,
        :owner => 'root:root'},

        {:template => 'apache_syslog',
        :path => '/usr/local/bin/apache_syslog',
        :mode => 0755,
        :owner => 'root:root'}
        
      ]

      task :config_gen do
        SYSTEM_CONFIG_FILES[:syslog_ng].each do |file|
          deprec2.render_template(:syslog_ng, file)
        end
      end

      desc "Push ssh config files to server"
      task :config do
        deprec2.push_configs(:syslog_ng, SYSTEM_CONFIG_FILES[:syslog_ng])
        restart
      end

      desc "Restart syslog-ng"
      task :restart do
        run "#{sudo} /etc/init.d/syslog-ng restart"
      end

    end
    
  end
end
