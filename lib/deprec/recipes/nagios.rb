# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :nagios do
      
      set :nagios_user, 'nagios'
      set :nagios_group, 'nagios'
      set(:nagios_host) { Capistrano::CLI.ui.ask "Enter hostname of nagios server" }
      set(:nagios_ip) { Capistrano::CLI.ui.ask "Enter ip address of nagios server" }
      set(:nagios_admin_pass) { Capistrano::CLI.ui.ask "Enter password for nagiosadmin user" }
      set :nagios_cmd_group, 'nagcmd' # Submit external commands through the web interface
      set :nagios_htpasswd_file, '/usr/local/nagios/etc/htpasswd.users'
      # default :application, 'nagios' 
      
      SRC_PACKAGES[:nagios] = {
        :url => "http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.3.tar.gz",
        :md5sum => "fe1be46e6976a52acdb021a782b5d04b  nagios-3.2.3.tar.gz",
        :configure => "./configure --with-command-group=nagcmd;",
        :make => 'make all;',
        :install => 'make install install-init install-commandmode install-webconf;'
      }
      
      desc "Install and configure Nagios server"
      task :setup_server, :roles => :nagios do
        install
        top.deprec.nagios_plugins.install
        top.deprec.nrpe.install
        config_gen
        config
      end
      
      desc "Setup client"
      task :setup_client do
        top.deprec.nagios_plugins.install
        top.deprec.nrpe.install
        top.deprec.nrpe.config
      end
      
      desc "Install nagios"
      task :install, :roles => :nagios do
        install_deps
        create_nagios_user
        deprec2.download_src(SRC_PACKAGES[:nagios], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nagios], src_dir)
      end
      
      # Install dependencies for nagios
      task :install_deps, :roles => :nagios do
        apt.install( {:base => %w(apache2 mailx postfix libapache2-mod-php5 libgd2-xpm-dev)}, :stable )
      end
      
      task :create_nagios_user, :roles => :nagios do
        deprec2.groupadd(nagios_group)
        deprec2.useradd(nagios_user, :group => nagios_group, :homedir => false)
        # deprec2.add_user_to_group(nagios_user, apache_user)
        deprec2.groupadd(nagios_cmd_group)
        deprec2.add_user_to_group(nagios_user, nagios_cmd_group)
        deprec2.add_user_to_group(apache_user, nagios_cmd_group)        
      end
      
      desc "Grant a user access to the web interface"
      task :htpass, :roles => :nagios do
        target_user = Capistrano::CLI.ui.ask "Userid" do |q|
          q.default = 'nagiosadmin'
        end
        system "htpasswd config/nagios/usr/local/nagios/etc/htpasswd.users #{target_user}"
      end
      
      # desc "Set password for web based access"
      # task :htpass do
      #   target_user = Capistrano::CLI.ui.ask "Userid" do |q| 
      #     q.default = 'nagiosadmin'
      #   end
      #   newpass = Capistrano::CLI.ui.ask "new password" do |q| 
      #     q.echo = false 
      #   end
      #   sudo "htpasswd -b #{htpasswd_file} #{target_user} #{newpass}"
      # end
      
      SYSTEM_CONFIG_FILES[:nagios] = [
        
        {:template => 'cgi.cfg.erb',
        :path => '/usr/local/nagios/etc/cgi.cfg',
        :mode => 0664,
        :owner => 'nagios:nagios'},
        
        {:template => 'htpasswd.users',
        :path => '/usr/local/nagios/etc/htpasswd.users',
        :mode => 0660,
        :owner => 'nagios:www-data'},
        
        {:template => 'nagios.cfg.erb',
        :path => '/usr/local/nagios/etc/nagios.cfg',
        :mode => 0664,
        :owner => 'nagios:nagios'},
        
        {:template => 'resource.cfg.erb',
        :path => '/usr/local/nagios/etc/resource.cfg',
        :mode => 0660,
        :owner => 'nagios:nagios'},
        
        {:template => 'objects/commands.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/commands.cfg',
        :mode => 0664,
        :owner => 'nagios:nagios'},
        
        {:template => 'objects/contacts.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/contacts.cfg',
        :mode => 0664,
        :owner => 'nagios:nagios'},
        
        {:template => 'objects/hosts.cfg.erb',
        :path => '/usr/local/nagios/etc/objects/hosts.cfg',
        :mode => 0664,
        :owner => 'nagios:nagios'},
        
        {:template => 'objects/localhost.cfg.erb',
         :path => '/usr/local/nagios/etc/objects/localhost.cfg',
         :mode => 0664,
         :owner => 'nagios:nagios'},
         
        {:template => 'objects/services.cfg.erb',
         :path => '/usr/local/nagios/etc/objects/services.cfg',
         :mode => 0664,
         :owner => 'nagios:nagios'},
        
        {:template => 'objects/timeperiods.cfg.erb',
         :path => '/usr/local/nagios/etc/objects/timeperiods.cfg',
         :mode => 0664,
         :owner => 'nagios:nagios'}
      
      ]

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
        send(run_method, "/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg")
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
        send(run_method, "/etc/init.d/nagios start")
      end

      desc "Stop Nagios"
      task :stop, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios stop")
      end

      desc "Restart Nagios"
      task :restart, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios restart")
      end

      desc "Reload Nagios"
      task :reload, :roles => :nagios do
        send(run_method, "/etc/init.d/nagios reload")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end
    
    end
    
    SRC_PACKAGES[:nagios_plugins] = {
      :url => "http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.15.tar.gz",
      :md5sum => "56abd6ade8aa860b38c4ca4a6ac5ab0d  nagios-plugins-1.4.15.tar.gz",
      :configure => "./configure --with-nagios-user=#{nagios_user} --with-nagios-group=#{nagios_group};",
    }   
          
    namespace :nagios_plugins do
    
      desc "Install nagios plugins"
      task :install do
        install_deps
        create_nagios_user
        deprec2.download_src(SRC_PACKAGES[:nagios_plugins], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nagios_plugins], src_dir)        
      end
      
      # Install dependencies for nagios plugins
      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev)}, :stable )
      end
      
      task :create_nagios_user do
        deprec2.groupadd(nagios_group)
        deprec2.useradd(nagios_user, :group => nagios_group, :homedir => false)
        # deprec2.add_user_to_group(nagios_user, apache_user)
        deprec2.groupadd(nagios_cmd_group)
        deprec2.add_user_to_group(nagios_user, nagios_cmd_group)
        deprec2.add_user_to_group(apache_user, nagios_cmd_group)        
      end
      
      
    end
    

    namespace :nrpe do
      
      default :nrpe_enable_command_args, false # set to true to compile nrpe to accept arguments
	                                       # note that you'll need to set it before these recipes are loaded (e.g. in .caprc)
      
      SRC_PACKAGES[:nrpe] = {
        :url => "http://downloads.sourceforge.net/nagios/nrpe-2.12.tar.gz",
        :md5sum => "b2d75e2962f1e3151ef58794d60c9e97  nrpe-2.12.tar.gz", 
        :configure => "./configure --with-nagios-user=#{nagios_user} --with-nagios-group=#{nagios_group} #{ '--enable-command-args' if nrpe_enable_command_args};",
        :make => 'make all;',
        :install => 'make install-plugin install-daemon install-daemon-config;'
      }
    
      desc 'Install NRPE'
      task :install do
        install_deps
        create_nagios_user
        deprec2.download_src(SRC_PACKAGES[:nrpe], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:nrpe], src_dir)
        # XXX this should only be run on the nrpe clients
        # XXX currently it's run on the nagios server too 
        # XXX shouldn't do any harm but we should split them up later 
        deprec2.append_to_file_if_missing('/etc/services', 'nrpe            5666/tcp # NRPE')    
        config
      end
      
      task :install_deps do
        apt.install( {:base => %w(xinetd libssl-dev openssl)}, :stable )
      end
      
      task :create_nagios_user do
        deprec2.groupadd(nagios_group)
        deprec2.useradd(nagios_user, :group => nagios_group, :homedir => false)
        # deprec2.add_user_to_group(nagios_user, apache_user)
        deprec2.groupadd(nagios_cmd_group)
        deprec2.add_user_to_group(nagios_user, nagios_cmd_group)
        deprec2.add_user_to_group(apache_user, nagios_cmd_group)        
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
        sudo "/etc/init.d/xinetd stop"  
        sudo "/etc/init.d/xinetd start"  
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
      
    # PNP4nagios
    # http://downloads.sourceforge.net/sourceforge/pnp4nagios/pnp-0.4.14.tar.gz?use_mirror=internode
    
    
  end
end
