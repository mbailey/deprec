# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :network do
            
      set(:network_number_of_ports) { 
        Capistrano::CLI.ui.ask "Number of network ports" do |q|
          q.default = 1
        end 
      }
      
      set(:network_interfaces) {
        foo = {}
        network_number_of_ports.to_i.times do |port|
          foo[port] = {}
          foo[port][:address] = Capistrano::CLI.ui.ask "address" do |q|
            q.default = "192.168.#{port+1}.10"
          end
          foo[port][:netmask] = Capistrano::CLI.ui.ask "netmask" do |q|
            q.default = '255.255.255.0'
          end
          foo[port][:broadcast] = Capistrano::CLI.ui.ask "broadcast" do |q|
            q.default = "192.168.#{port+1}.255"
          end

        end
        foo
      }
      set(:network_hostname) { 
        Capistrano::CLI.ui.ask "hostname" do |q|
          # q.validate = /add hostname validation here/
        end 
      } 
      set(:network_gateway) { 
        Capistrano::CLI.ui.ask "default gateway" do |q|
          q.default = '192.168.1.1'
        end 
      }
      set(:network_dns_nameservers) { 
        Capistrano::CLI.ui.ask "dns nameservers (separated by spaces)" do |q|
          q.default = '203.8.183.1 4.2.2.1'
        end 
      }
      
      SYSTEM_CONFIG_FILES[:network] = [

        {:template => "interfaces.erb",
          :path => '/etc/network/interfaces',
          :mode => 0644,
          :owner => 'root:root'},

        {:template => "hosts.erb",
         :path => '/etc/hosts',
         :mode => 0644,
         :owner => 'root:root'},

        {:template => "hostname.erb",
         :path => '/etc/hostname',
         :mode => 0644,
         :owner => 'root:root'}
    
       ]
       
      # XXX need to set the order for these as it breaks sudo currently
      desc "Update system networking configuration"
      task :config do
        SYSTEM_CONFIG_FILES[:network].each do |file|
          deprec2.render_template(:network, file.merge(:remote=>true))
        end
      end
      
      desc "Restart network interface"
      task :restart do
        sudo '/etc/init.d/networking restart'
      end
      
      
    end
  end
  
end