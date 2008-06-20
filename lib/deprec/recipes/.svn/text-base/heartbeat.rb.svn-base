# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :heartbeat do
      set(:heartbeat_nodes) { find_servers_for_task(current_task) }
      set(:heartbeat_preferred_node) {
        Capistrano::CLI.ui.choose do |menu| 
          heartbeat_nodes.each {|c| menu.choice(c)}
          menu.header = "select preferred node"
        end
      }
      set(:heartbeat_resources) {Capistrano::CLI.ui.ask 'Enter resource to share. e.g. an ip address'}
      set(:heartbeat_auth_key) { Capistrano::CLI.ui.ask 'Enter auth key for heartbeat to use' } 
      set(:heartbeat_ping) { Capistrano::CLI.ui.ask 'Enter IP address nodes will ping to test connectivity. e.g. gateway address' } 
      set(:heartbeat_bcast) { 
        Capistrano::CLI.ui.ask 'Enter ethernet interface(s) Heartbeat sends UDP broadcast traffic on. e.g. eth0' do |q|
          q.default = 'eth0'
        end
        } 
      set(:heartbeat_auto_failback) { 
        Capistrano::CLI.ui.ask 'Should resource(s) automatically fail back to its "primary" node ' do |q|
          q.default = 'yes'
        end
      }
      
      desc "Install Heartbeat"
      task :install do
        install_deps
      end
         
      # Install dependencies for heartbeat
      task :install_deps do
        apt.install( {:base => %w(heartbeat-2)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:heartbeat] = [
        
        {:template => 'ha.cf.erb',
        :path => '/etc/ha.d/ha.cf',
        :mode => 0644,
        :owner => 'root:root'},
        
        {:template => 'haresources.erb',
        :path => '/etc/ha.d/haresources',
        :mode => 0644,
        :owner => 'root:root'},
        
        {:template => 'authkeys.erb',
        :path => '/etc/ha.d/authkeys',
        :mode => 0600,
        :owner => 'root:root'}
        
      ]

      desc "Generate configuration file(s) for heartbeat from template(s)"
      task :config_gen do
        if ENV['ROLES'] 
          SYSTEM_CONFIG_FILES[:heartbeat].each do |file|
            file.merge!({:path => "#{file[:path]}-#{ENV['ROLES']}"})
            deprec2.render_template(:heartbeat, file)
          end
        else
          puts
          puts "Whoops!"
          puts
          puts "You need to specify the cluster to work on by defining ROLES env variable."
          puts "e.g. cap deprec:heartbeat:config ROLES=cluster_web"
          puts 
        end
      end
      
      desc "Push heartbeat config files to server"
      task :config do
        if ENV['ROLES']
          config_files = SYSTEM_CONFIG_FILES[:heartbeat].collect{|file| file.merge({:path => "#{file[:path]}-#{ENV['ROLES']}"})}
          deprec2.push_configs(:heartbeat, config_files)
          SYSTEM_CONFIG_FILES[:heartbeat].each {|file|
            sudo "mv #{file[:path]}-#{ENV['ROLES']} #{file[:path]}"
          }
          # puts config_files
        else
          puts 
          puts "Whoops!"
          puts
          puts "You need to specify the cluster to work on by defining ROLES env variable."
          puts "e.g. cap deprec:heartbeat:config ROLES=cluster_web"
          puts 
        end
      end
      
      desc "Set Heartbeat to start on boot"
      task :activate, :roles => :heartbeat do
        send(run_method, "update-rc.d heartbeat defaults")
      end
      
      desc "Set Heartbeat to not start on boot"
      task :deactivate, :roles => :heartbeat do
        send(run_method, "update-rc.d -f heartbeat remove")
      end
      
      
      # Control

      # XXX perhaps define a cluster to work with
      # XXX e.g. set :cluster, 'rolename'
      # XXX and then target that rolename with these tasks
      
      desc "Start Heartbeat"
      task :start, :roles => :heartbeat do
        send(run_method, "/etc/init.d/heartbeat start")
      end

      desc "Stop Heartbeat"
      task :stop, :roles => :heartbeat do
        send(run_method, "/etc/init.d/heartbeat stop")
      end

      desc "Restart Heartbeat"
      task :restart, :roles => :heartbeat do
        send(run_method, "/etc/init.d/heartbeat restart")
      end

      desc "Reload Heartbeat"
      task :reload, :roles => :heartbeat do
        send(run_method, "/etc/init.d/heartbeat reload")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end
          
    end
  end
end