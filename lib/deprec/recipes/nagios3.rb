# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nagios do
      
      # set(:nagios_host) { Capistrano::CLI.ui.ask "Enter hostname of nagios server" }
      # set(:nagios_ip) { Capistrano::CLI.ui.ask "Enter ip address of nagios server" }
      # set(:nagios_admin_pass) { Capistrano::CLI.ui.ask "Enter password for nagiosadmin user" }
      # set :nagios_cmd_group, 'nagcmd' # Submit external commands through the web interface
      # set :nagios_htpasswd_file, '/usr/local/nagios/etc/htpasswd.users'
      # default :application, 'nagios' 
      
      desc "Install Nagios"
      task :install, :roles => :nagios do
        apt.install( {:base => %w(nagios3 nagios-plugins nagios-nrpe-plugin)}, :stable )
        config
      end
      
      desc "Grant a user access to the web interface"
      task :htpass, :roles => :nagios do
        target_user = Capistrano::CLI.ui.ask "Userid" do |q|
          q.default = 'nagiosadmin'
        end
        system "htpasswd config/nagios/usr/local/nagios/etc/htpasswd.users #{target_user}"
        config
      end

      SYSTEM_CONFIG_FILES[:nagios] ||= []
      %w( 
        apache2.conf
        cgi.cfg
        commands.cfg
        htpasswd.users
        nagios.cfg
        nrpe.cfg
        resource.cfg
        conf.d/contacts_nagios2.cfg
        conf.d/extinfo_nagios2.cfg
        conf.d/generic-host_nagios2.cfg
        conf.d/generic-service_nagios2.cfg
        conf.d/hostgroups_nagios2.cfg
        conf.d/localhost_nagios2.cfg
        conf.d/services_nagios2.cfg
        conf.d/timeperiods_nagios2.cfg 
      ).each do |filename|
        SYSTEM_CONFIG_FILES[:nagios] << {
          :template => "#{filename}",
          :path => "/etc/nagios3/#{filename}",
          :mode => 0644,
          :owner => 'root:root'
        }
      end

      desc "Generate configuration file(s) for nagios from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:nagios].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end
      
      desc "Push nagios config files to server"
      task :config, :roles => :nagios do
        default :application, 'nagios'
        deprec2.push_configs(:nagios, SYSTEM_CONFIG_FILES[:nagios])
        config_check
        restart
      end
      
      desc "Run Nagios config check"
      task :config_check, :roles => :nagios do
        send(run_method, "/usr/sbin/nagios3 -v /etc/nagios3/nagios.cfg")
      end
      
      # desc "Set Nagios to start on boot"
      # task :activate, :roles => :nagios do
      #   send(run_method, "update-rc.d nagios defaults")
      #   sudo "a2ensite nagios"
      #   top.deprec.apache.reload
      # end
      # 
      # desc "Set Nagios to not start on boot"
      # task :deactivate, :roles => :nagios do
      #   send(run_method, "update-rc.d -f nagios remove")
      #   sudo "a2dissite nagios"
      #   top.deprec.apache.reload
      # end
      
      # Control

      desc "Start Nagios"
      task :start, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios3 start")
      end

      desc "Stop Nagios"
      task :stop, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios3 stop")
      end

      desc "Restart Nagios"
      task :restart, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios3 restart")
      end

      desc "Reload Nagios"
      task :reload, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios3 reload")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end
    
    end
    
    namespace :nrpe do
      
      default :nrpe_enable_command_args, false # set to true to compile nrpe to accept arguments
	                                       # note that you'll need to set it before these recipes are loaded (e.g. in .caprc)
      
      desc 'Install NRPE'
      task :install do
        apt.install( {:base => %w(nagios-nrpe-server nagios-plugins nagios-nrpe-plugin)}, :stable )
        config
      end
      
      SYSTEM_CONFIG_FILES[:nrpe] = [
        
        {:template => 'nrpe.xinetd.erb',
         :path => "/etc/xinetd.d/nrpe",
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => 'nrpe.cfg.erb',
         :path => "/usr/local/nagios/etc/nrpe.cfg",
         :mode => 0644,
         :owner => 'nagios:nagios'}, # XXX hard coded file owner is bad...
                                    # It's done here because we aren't using 
                                    # lazy eval in hash constant.
        {:template => "check_mongrel_cluster.rb",
         :path => '/usr/local/nagios/libexec/check_mongrel_cluster.rb',
         :mode => 0755,
         :owner => 'root:root'},
         
         {:template => "check_linux_free_memory.pl",
          :path => '/usr/local/nagios/libexec/check_linux_free_memory.pl',
          :mode => 0755,
          :owner => 'root:root'}
      
      ]
      
      desc "Generate configuration file(s) for nrpe from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:nrpe].each do |file|
          deprec2.render_template(:nagios, file)
        end
      end
      
      desc "Push nrpe config files to server"
      task :config do
        deprec2.push_configs(:nagios, SYSTEM_CONFIG_FILES[:nrpe])
        # XXX should really only do this on targets
        # sudo "/etc/init.d/xinetd stop"  
        # sudo "/etc/init.d/xinetd start"  
      end
      
      desc "Test whether NRPE is listening on client"
      task :test_local do
        run "/usr/local/nagios/libexec/check_nrpe -H localhost"
      end
      
      desc "Test whether nagios server can query client via NRPE"
      task :test_remote, :roles => :nagios do
        target_host = Capistrano::CLI.ui.ask "target hostname"
        run "/usr/local/nagios/libexec/check_nrpe -H #{target_host}"
      end
  
    end
      
  end
end
