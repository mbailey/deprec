# Copyright 2006-2008 by Mike Bailey. All rights reserved.
require 'socket'
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nagios do

      # Deprec generally ships with the upstream vendor defaults
      # 
      # In this case we override the default settings Nagios ships with 
      # to enable external command checking. This is needed if you want
      # to be able to control things via the web interface.
      set :nagios_check_external_commands, 1
      set :nagios_command_check_interval, '15s'
      
      desc "Install Nagios"
      task :install, :roles => :nagios do
        apt.install( 
          {:base => %w(nagios3 nagios-plugins nagios-nrpe-plugin)}, :stable 
        )
        cull_configs
        config
        fix_command_file
        puts
        puts "Nagios should be accessible at #{find_servers_for_task(current_task).collect{|u| "http://#{u}/nagios3"}.join(' ')}"
      end

      task :cull_configs, :roles => :nagios do
        %w(/etc/nagios3/conf.d/localhost_nagios2.cfg
           /etc/nagios3/conf.d/host-gateway_nagios3.cfg).each do |file|
          run "if [ -f #{file} ]; then #{sudo} rm #{file}; fi"
        end
      end

      task :fix_command_file, :roles => :nagios do
        stop
        sleep 5 # Give the stop command time to work. Race condition. GROSS!!
        run "(dpkg-statoverride --list | grep 'nagios www-data 2710 /var/lib/nagios3/rw') || #{sudo} dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw"
        run "(dpkg-statoverride --list | grep 'nagios nagios 751 /var/lib/nagios3') || 
              #{sudo} dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3"
        # sleep 5
        start
      end
      
      desc "Grant a user access to the web interface"
      task :htpass, :roles => :nagios do
        target_user = Capistrano::CLI.ui.ask "Userid" do |q|
          q.default = 'nagiosadmin'
        end
        htpasswd_file = 'config/nagios/usr/local/nagios/etc/htpasswd.users'
        system "htpasswd #{htpasswd_file} #{target_user}"
        config
      end

      # All of the config files have same owner/mode...
      SYSTEM_CONFIG_FILES[:nagios] ||= []
      %w( 
        apache2.conf
        cgi.cfg
        commands.cfg
        htpasswd.users
        nagios.cfg
        conf.d/contacts_nagios2.cfg
        conf.d/extinfo_nagios2.cfg
        conf.d/generic-host_nagios2.cfg
        conf.d/generic-service_nagios2.cfg
        conf.d/hostgroups_nagios2.cfg
        conf.d/services_nagios2.cfg
        conf.d/timeperiods_nagios2.cfg 
        conf.d/hosts/localhost_nagios2.cfg
      ).each do |filename|
        SYSTEM_CONFIG_FILES[:nagios] << {
          :path => "/etc/nagios3/#{filename}",
          :template => "#{filename}",
          :mode => 0644,
          :owner => 'root:root'
        }
      end
      # ..except this one.
      SYSTEM_CONFIG_FILES[:nagios] << {
        :path => "/etc/nagios3/resource.cfg",
        :template => "resource.cfg",
        :mode => 0640,
        :owner => 'root:nagios'
      }

      desc "Generate configuration file(s) for nagios from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:nagios].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end
      
      desc "Push nagios config files to server"
      task :config, :roles => :nagios do
        add_host_configs
        deprec2.push_configs(:nagios, SYSTEM_CONFIG_FILES[:nagios])
        config_check
        reload
      end

      # Dynamically add host config files to SYSTEM_CONFIG_FILES[:nagios]
      task :add_host_configs, :roles => :nagios do
        host_conf_dir =  'config/nagios/etc/nagios3/conf.d/hosts'
        if File.directory? host_conf_dir
          Dir.foreach(host_conf_dir).reject{|f| f =~ /\.\.?$/}.each do |filename|
            SYSTEM_CONFIG_FILES[:nagios] << {
              :path => "/etc/nagios3/conf.d/hosts/#{filename}",
              :mode => 0644,
              :owner => 'root:root'
            }
          end
        end
      end
      
      desc "Run Nagios config check"
      task :config_check, :roles => :nagios do
        run "#{sudo} /usr/sbin/nagios3 -v /etc/nagios3/nagios.cfg"
      end

      desc "Generate a nagios host config file"
      task :gen_host do
        set(:nagios_target_host_name) { Capistrano::CLI.ui.ask "hostname"}
        set(:nagios_target_hostgroups) { 
          Capistrano::CLI.ui.ask "hostgroups" do |q|
            q.default = 'linux-servers'
          end
        }
        set(:nagios_target_address) { 
          Capistrano::CLI.ui.ask "ip address" do |q|
            q.default = IPSocket.getaddress(nagios_target_host_name)
          end
        }
        file = {
          :path => "/etc/nagios3/conf.d/hosts/#{nagios_target_host_name}.cfg",
          :template => "host_template.erb",
          :mode => 0644,
          :owner => 'root:root'
        }
        deprec2.render_template(:nagios, file)
        puts
        puts "You can push it to the server with:"
        puts 
        puts "  cap deprec:nagios:config"
        puts
      end
      
      # Control

      desc "Start Nagios"
      task :start, :roles => :nagios do
        run "#{sudo} /etc/init.d/nagios3 start"
      end

      desc "Stop Nagios"
      task :stop, :roles => :nagios do
        run "#{sudo} /etc/init.d/nagios3 stop"
      end

      desc "Restart Nagios"
      task :restart, :roles => :nagios do
        run "#{sudo} /etc/init.d/nagios3 restart"
      end

      desc "Reload Nagios"
      task :reload, :roles => :nagios do
        run "#{sudo} /etc/init.d/nagios3 reload"
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
