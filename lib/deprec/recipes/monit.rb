# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :monit do
    
  # We're using monit primarily to control Mongrel processes so 
  # the tasks are restricted to :app. You may with to use it for
  # other processes. In this case, specify HOSTS=hostname on the
  # command line or use: 
  #   for_roles(:role_name) { top.deprec.monit.task_name}
  # in your recipes.
        
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
    :md5sum => "4bbd3845ae1cbab13ec211824e0486dc  monit-5.1.1.tar.gz", 
    :url => "http://mmonit.com/monit/dist/monit-5.1.1.tar.gz"
  }
  
  desc "Install monit"
  task :install, :roles => :app do
    install_deps
    deprec2.download_src(SRC_PACKAGES[:monit], src_dir)
    deprec2.install_from_src(SRC_PACKAGES[:monit], src_dir)
    # Initial push of system files - not kept locally
    SYSTEM_CONFIG_FILES[:monit].each do |file|
      deprec2.render_template(:monit, file.merge(:remote=>true))
    end
    activate
  end
  
  # install dependencies for monit
  task :install_deps, :roles => :app do
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
      
    {:template => 'nothing.monitrc',
     :path => "/etc/monit.d/nothing.monitrc",
     :mode => 0700,
     :owner => 'root:root'}
  ]
  
  desc <<-DESC
  Generate monit config from template. Note that this does not
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
  task :config, :roles => :app do
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
  task :activate, :roles => :app do
    send(run_method, "update-rc.d monit defaults")
  end
  
  desc <<-DESC
    Dectivate monit start scripts on server.
    Setup server to start monit on boot.
  DESC
  task :deactivate, :roles => :app do
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
