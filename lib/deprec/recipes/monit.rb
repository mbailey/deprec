# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :monit do
        
  set :monit_user,  'monit'
  set :monit_group, 'monit'
  set :monit_confd_dir, '/etc/monit.d'
  
  set :monit_check_interval, 60
  set :monit_log, 'syslog facility log_daemon'
  set :monit_mailserver, nil
  set :monit_mail_from, 'monit@deprec.enabled.slice'
  set :monit_alert_recipients, %w(root@localhost)
  set :monit_timeout_recipients, %w(root@localhost)
  set :monit_webserver_enabled, true
  set :monit_webserver_port, 2812
  set :monit_webserver_address, 'localhost'
  set :monit_webserver_allowed_hosts_and_networks, %w(localhost)
  set :monit_webserver_auth_user, 'admin'
  set :monit_webserver_auth_pass, 'monit'
  
  # Upstream changes: http://www.tildeslash.com/monit/dist/CHANGES.txt  
  # Ubuntu package version = monit-4.8.1  
  SRC_PACKAGES[:monit] = {
    :filename => 'monit-4.10.1.tar.gz',   
    :md5sum => "d3143b0bbd79b53f1b019d2fc1dae656  monit-4.10.1.tar.gz", 
    :dir => 'monit-4.10.1',  
    :url => "http://www.tildeslash.com/monit/dist/monit-4.10.1.tar.gz",
    :unpack => "tar zxf monit-4.10.1.tar.gz;",
    :configure => %w(
      ./configure
      ;
      ).reject{|arg| arg.match '#'}.join(' '),
    :make => 'make;',
    :install => 'make install;'
  }
  
  desc "Install monit"
  task :install do
    install_deps
    deprec2.download_src(SRC_PACKAGES[:monit], src_dir)
    deprec2.install_from_src(SRC_PACKAGES[:monit], src_dir)
  end
  
  # install dependencies for monit
  task :install_deps do
    apt.install( {:base => %w(flex bison libssl-dev)}, :stable )
  end
    
  SYSTEM_CONFIG_FILES[:monit] = [
    
    {:template => 'monit-init-script',
     :path => '/etc/init.d/monit',
     :mode => 0755,
     :owner => 'root:root'},
     
    {:template => 'monitrc.erb',
     :path => "/etc/monitrc",
     :mode => 0700,
     :owner => 'root:root'},
      
    {:template => 'nothing',
     :path => "/etc/monit.d/nothing",
     :mode => 0700,
     :owner => 'root:root'}
  ]
  
  desc <<-DESC
  Generate nginx config from template. Note that this does not
  push the config to the server, it merely generates required
  configuration files. These should be kept under source control.            
  The can be pushed to the server with the :config task.
  DESC
  task :config_gen do
    SYSTEM_CONFIG_FILES[:monit].each do |file|
      deprec2.render_template(:monit, file)
    end
  end
  
  desc "Push monit config files to server"
  task :config do
    deprec2.push_configs(:monit, SYSTEM_CONFIG_FILES[:monit])
  end

  desc "Start Monit"
  task :start, :roles => :app do
    send(run_method, "/etc/init.d/monit start")
  end

  desc "Stop Monit"
  task :stop, :roles => :app  do
    send(run_method, "/etc/init.d/monit stop")
  end

  desc "Restart Monit"
  task :restart, :roles => :app  do
    send(run_method, "/etc/init.d/monit restart")
  end

  desc "Reload Monit"
  task :reload, :roles => :app  do
    send(run_method, "/etc/init.d/monit reload")
  end
   
  desc <<-DESC
    Activate monit start scripts on server.
    Setup server to start monit on boot.
  DESC
  task :activate do
    send(run_method, "update-rc.d monit defaults")
  end
  
  desc <<-DESC
    Dectivate monit start scripts on server.
    Setup server to start monit on boot.
  DESC
  task :deactivate do
    send(run_method, "update-rc.d -f monit remove")
  end
  
  task :backup do
    # there's nothing to backup for monit
  end
  
  task :restore do
    # there's nothing to restore for monit
  end

  end end
end