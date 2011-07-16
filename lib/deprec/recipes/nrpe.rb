# Copyright 2006-2011 by Mike Bailey. All rights reserved.
require 'socket'
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nrpe do

      set(:nrpe_allowed_hosts) { 
        Capistrano::CLI.ui.ask("Address(es) of Nagios server(s) (comma sep)")
      }

      desc 'Install NRPE'
      task :install, :roles => :nrpe do
        apt.install( {:base => %w(nagios-nrpe-server nagios-plugins 
                                  nagios-nrpe-plugin)}, :stable )
        config
      end
      
      SYSTEM_CONFIG_FILES[:nrpe] = [

        {
          :path => "/etc/nagios/nrpe.cfg",
          :template => "nrpe.cfg",
          :mode => 0644,
          :owner => 'root:root'
        }

      ]
      
      desc "Generate configuration file(s) for nrpe from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:nrpe].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end
      
      desc "Push nrpe config files to server"
      task :config, :roles => :nrpe do
        deprec2.push_configs(:nagios, SYSTEM_CONFIG_FILES[:nrpe])
        reload
        test_local
      end

      # Control

      desc "Start NRPE"
      task :start, :roles => :nrpe do
        send(run_method, "/etc/init.d/nagios-nrpe-server start")
      end

      desc "Stop NRPE"
      task :stop, :roles => :nrpe do
        send(run_method, "/etc/init.d/nagios-nrpe-server stop")
      end

      desc "Restart NRPE"
      task :restart, :roles => :nrpe do
        send(run_method, "/etc/init.d/nagios-nrpe-server restart")
      end

      desc "Reload NRPE"
      task :reload, :roles => :nrpe do
        send(run_method, "/etc/init.d/nagios-nrpe-server reload")
      end

      # Extras
      
      desc "Test whether NRPE is listening on client"
      task :test_local, :roles => :nrpe do
        puts "Testing that NRPE is listening on client"
        run "/usr/lib/nagios/plugins/check_nrpe -H localhost"
      end
      
      desc "Test whether nagios server can query client via NRPE"
      task :test_remote, :roles => :nagios do
        target_host = Capistrano::CLI.ui.ask "target hostname"
        run "/usr/lib/nagios/plugins/check_nrpe -H #{IPSocket.getaddress(target_host)}"
      end
  
    end
      
  end
end
