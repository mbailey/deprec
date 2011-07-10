# Copyright 2006-2008 by Mike Bailey. All rights reserved.
require 'socket'
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :network do
            
      set(:network_number_of_ports) { 
        Capistrano::CLI.ui.ask "Number of network interfaces" do |q|
          q.default = 1
        end 
      }
      
      default_network = ''
      set(:network_interfaces) {
        result = {}
        network_number_of_ports.to_i.times do |iface|
          default_network = "192.168.#{iface+1}"
          result[iface] = {}
          result[iface][:address] = Capistrano::CLI.ui.ask "address" do |q|
            if network_hostname
              q.default = IPSocket.getaddress(network_hostname) rescue "#{default_network}.10"
            else
              q.default = "#{default_network}.10"
            end
          end
          default_network = result[iface][:address].split('.').slice(0,3).join('.')
          result[iface][:netmask] = Capistrano::CLI.ui.ask "netmask" do |q|
            q.default = "255.255.255.0"
          end
          result[iface][:broadcast] = Capistrano::CLI.ui.ask "broadcast" do |q|
            q.default = "#{default_network}.255"
          end
        end
        result
      }
      set(:network_hostname) { 
        Capistrano::CLI.ui.ask "Enter the hostname for the server" do |q|
          # q.validate = /add hostname validation here/
        end 
      } 
      set(:network_gateway) { 
        Capistrano::CLI.ui.ask "default gateway" do |q|
          q.default = "#{default_network}.1"
        end 
      }
      set(:network_dns_nameservers) { 
        Capistrano::CLI.ui.ask "dns nameservers (separated by spaces)" do |q|
          q.default = '203.8.183.1 4.2.2.1'
        end 
      }
      set(:network_dns_search_path) { 
        Capistrano::CLI.ui.ask "dns search domains (separated by spaces)" do |q|
          q.default = nil
        end 
      }
      
      # Non standard deprec!
      #
      # SYSTEM_CONFIG_FILES[:network] would normally be an array
      #
      # I might move to making this standard in future. It makes it easier to 
      # override individual config files in local recipes. - Mike
      #
      SYSTEM_CONFIG_FILES[:network] = {

        :hostname => {
            :template => "hostname.erb",
            :path => '/etc/hostname',
            :mode => 0644,
            :owner => 'root:root',
            :remote => true
        },

        :hosts => {
           :template => "hosts.erb",
           :path => '/etc/hosts',
           :mode => 0644,
           :owner => 'root:root',
           :remote => true
        },

        :interfaces => {
           :template => "interfaces.erb",
           :path => '/etc/network/interfaces',
           :mode => 0644,
           :owner => 'root:root',
           :remote => true
        },
         
        :resolv => {
          :template => "resolv.conf.erb",
          :path => '/etc/resolv.conf',
          :mode => 0644,
          :owner => 'root:root',
          :remote => true
        }
      }
    
      desc "Generate and push all network config files"
      task :config do
        if find_servers_for_task(current_task).size != 1
          puts "****************************************************"
          puts "*** You must specify exactly 1 host to configure ***"
          puts "****************************************************"
        else
          hostname
          hosts
          interfaces
          resolv
          restart
        end
      end
      
      desc "Restart networking "
      task :restart do
        # This is the only task that is designed to 'fail'
        # Solutions to this problem welcome!
        servers = find_servers_for_task(current_task).join(',')
        puts
        puts "About to restart networking on #{servers}"
        # In an effort to appeal to younger devs we're using 'street talk'
        input = Capistrano::CLI.ui.ask "Are you 'down with that'?" do |q|
          q.default = 'y'
        end
        if input =~ /y/i
          run "#{sudo} /etc/init.d/networking restart"
        else
          puts "You can always do it later with"
          puts
          puts "  cap deprec:network:restart HOSTS=#{servers}"
          puts
        end
      end

      # Create individual tasks to generate remote config files
      #
      # e.g. cap deprec:network:hostname
      #
      SYSTEM_CONFIG_FILES[:network].each do |file, details|
        desc "Generate and push #{details[:path]}"
        task file.to_sym do
          deprec2.render_template(:network, details)
          run "#{sudo} hostname #{network_hostname}" if file == :hostname
        end
      end
            
    end
  end
  
end
