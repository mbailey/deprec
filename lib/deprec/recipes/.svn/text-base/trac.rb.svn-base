# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :trac do
        
  # Master tracd process for server
  set :tracd_cmd, '/usr/bin/tracd'
  set :tracd_port, '9000'
  set :tracd_pidfile, '/var/run/tracd.pid'
  
  # Settings for this projects trac instance
  set(:tracd_domain_root) { domain.sub(/.*?\./,'') } # strip subdomain from domain
  set(:tracd_vhost_domain) { "trac-#{application}.#{tracd_domain_root}" } # nginx will proxy this domain to tracd
  
  set(:trac_backup_dir) { "#{backup_dir}/trac" }
  set(:trac_path) { exists?(:deploy_to) ? "#{deploy_to}/trac" : Capistrano::CLI.ui.ask('path to trac config') }
  set(:tracd_parent_dir) { "/etc/trac.d" }
  set(:trac_password_file)  { "#{trac_path}/conf/users.htdigest" }
  set(:trac_account) { Capistrano::CLI.prompt('enter new trac user account name') }
  set :trac_passwordfile_exists, true # hack - should check on remote system instead
  set(:trac_header_logo_link) { trac_home_url }
  # We will symlink each projects trac dir into this dir for tracd to find

  # project
  set(:trac_domain) { domain.sub(/^.*?\./, 'trac.') }
  set(:trac_home_url) { "http://#{trac_domain}/" }
  set(:trac_desc) { application } 
  
  # Settings only used for generating trac.ini for this project
  # - notification
  set :trac_always_notify_owner, false
  set :trac_always_notify_reporter, false
  set :trac_always_notify_updater, true
  set :trac_smtp_always_bcc, ''
  set :trac_smtp_always_cc, ''
  set :trac_smtp_default_domain, ''
  set :trac_smtp_enabled, true
  set :trac_smtp_from, 'trac@localhost'
  set :trac_smtp_password, ''
  set :trac_smtp_port, 25
  set :trac_smtp_replyto, 'trac@localhost'
  set :trac_smtp_server, 'localhost'
  set :trac_smtp_subject_prefix, '__default__'
  set :trac_smtp_user, ''
  set :trac_use_public_cc, false
  set :trac_use_short_addr, false
  set :trac_use_tls, false  
  # - other
  set(:trac_base_url) { trac_home_url }
  
  desc "Install trac on server"
  task :install, :roles => :scm do
    install_deps
    sudo "easy_install Trac==0.11rc1"
    create_pid_dir
    create_parent_dir
    config_gen_system
    config_system
    activate_system
  end
  
  task :install_deps do
    apt.install( {:base => %w(sqlite3 python-setuptools python-subversion)}, :stable )
  end
  
  # The start script has a couple of config values in it.
  # We may want to extract them into a config file later
  # and install this script as part of the :install task.
  SYSTEM_CONFIG_FILES[:trac] = [
    {:template => 'tracd-init.erb',
     :path => '/etc/init.d/tracd',
     :mode => 0755,
     :owner => 'root:root'}
  ]
  
  PROJECT_CONFIG_FILES[:trac] = [
    {:template => 'users.htdigest.erb',
     :path => "conf/users.htdigest",
     :mode => 0644,
     :owner => 'root:root'},
     
    {:template => 'trac.ini.erb',
     :path => "conf/trac.ini",
     :mode => 0644,
     :owner => 'root:root'},
     
    {:template => 'nginx_vhost.conf.erb',
     :path => "conf/nginx_vhost.conf",
     :mode => 0644,
     :owner => 'root:root'}
  ]
  
  desc "Generate config files for trac"
  task :config_gen do
    config_gen_system
    config_gen_project
  end
  
  task :config_gen_system do
    SYSTEM_CONFIG_FILES[:trac].each do |file|
      deprec2.render_template(:trac, file)
    end
  end
  
  task :config_gen_project do
    PROJECT_CONFIG_FILES[:trac].each do |file|
      deprec2.render_template(:trac, file)
    end
  end
  
  desc "Push trac config files to server"
  task :config, :roles => :scm do
    config_system
    config_project
    restart
    top.deprec.nginx.restart
  end
  
  task :config_system, :roles => :scm do
    deprec2.push_configs(:trac, SYSTEM_CONFIG_FILES[:trac])
  end
  
  task :config_project, :roles => :scm do
    deprec2.push_configs(:trac, PROJECT_CONFIG_FILES[:trac])
    symlink_nginx_vhost
  end

  desc "Initialize the trac db for this project"
  task :setup, :roles => :scm do
    init
    config_gen_project
    config_project
    activate_project
    # set_default_permissions  # XXX re-enable this
    # create trac account for current user 
    set :trac_account, user
    set :trac_passwordfile_exists, false # hack - should check on remote system instead
    # user_add # XXX re-enable
  end
  
  task :init, :roles => :scm do
    deprec2.mkdir(trac_path, :via => :sudo)
    sudo "trac-admin #{trac_path} initenv #{application} sqlite:db/trac.db svn #{repos_root}"
  end
  
  task :set_default_permissions, :roles => :scm do
    anonymous_disable
    authenticated_enable
  end
  
  task :start, :roles => :scm do
    sudo "/etc/init.d/tracd start"
  end

  task :stop, :roles => :scm do
    sudo "/etc/init.d/tracd stop"
  end
  
  task :restart, :roles => :scm do
    stop
    start
  end

  task :activate, :roles => :scm do
    activate_system
    activate_project
  end
  
  task :activate_system, :roles => :scm do
    sudo "update-rc.d tracd defaults"
  end
  
  task :activate_project, :roles => :scm do
    symlink_project
  end
  
  task :deactivate, :roles => :scm do
    deactivate_system
    deactivate_project
  end
  
  task :deactivate_system, :roles => :scm do
    sudo "update-rc.d -f tracd remove"
  end
  
  task :deactivate_project, :roles => :scm do
    unlink_project
    unlink_nginx_vhost
    restart
  end
  
  desc "Create backup of trac repository"
  task :backup, :roles => :web do
    # http://trac.edgewall.org/wiki/TracBackup
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    dest_dir = File.join(trac_backup_dir, "trac_#{application}_#{timestamp}")
    sudo "trac-admin #{trac_path} hotcopy #{dest_dir}"
  end
  
  desc "Restore trac repository from backup"
  task :restore, :roles => :web do
    # prompt user to select from list of locally stored backups
    # tracd_stop
    # copy out backup
  end
  
  #
  # Service specific tasks for end users
  #
  desc "create a trac user"
  task :user_add, :roles => :scm do
    create_file = trac_passwordfile_exists ? '' : ' -c '
    htdigest = '/usr/local/apache2/bin/htdigest'
    # XXX check if htdigest file exists and add '-c' option if not
    # sudo "test -f #{trac_path/conf/users.htdigest}
    create_file = trac_passwordfile_exists ? '' : ' -c '
    deprec2.sudo_with_input("#{htdigest} #{create_file} #{trac_path}/conf/users.htdigest #{application} #{trac_account}", /password:/) 
  end
  
  desc "list trac users"
  task :list_users, :roles => :scm do
    sudo "cat #{trac_path}/conf/users.htdigest"
  end
  
  # desc "disable anonymous access to everything"
  task :anonymous_disable, :roles => :scm do
    sudo "trac-admin #{trac_path} permission remove anonymous '*'"
  end
  
  # desc "enable authenticated users access to everything"
  task :authenticated_enable, :roles => :scm do
    sudo "trac-admin #{trac_path} permission add authenticated TRAC_ADMIN"
  end
  
  #
  # Helper tasks used by other tasks
  #
  
  # Link the trac repos for this project into the master trac repos dir
  # We do this so we can use trac for multiple projects on the same server
  task :symlink_project, :roles => :scm do
    sudo "ln -sf #{trac_path} #{tracd_parent_dir}/#{application}"
  end
  
  task :unlink_project, :roles => :scm do
    link = "#{tracd_parent_dir}/#{application}"
    sudo "test -h #{link} && sudo unlink #{link} || true"
  end
  
  task :symlink_nginx_vhost, :roles => :scm do
    sudo "ln -sf #{deploy_to}/trac/conf/nginx_vhost.conf #{nginx_vhost_dir}/tracd-#{application}.conf"
  end
  
  task :unlink_nginx_vhost, :roles => :scm do
    link = "#{nginx_vhost_dir}/tracd-#{application}.conf"
    sudo "test -h #{link} && unlink #{link} || true"
  end
  
  # task :symlink_apache_vhost, :roles => :scm do
  #   sudo "ln -sf #{deploy_to}/trac/conf/trac_apache_vhost.conf #{apache_vhost_dir}/#{application}-trac.conf"
  # end
  # 
  # task :unlink_apache_vhost, :roles => :scm do
  #   link = "#{apache_vhost_dir}/#{application}-trac.conf"
  #   sudo "test -h #{link} && unlink #{link} || true"
  # end
  
  task :create_pid_dir, :roles => :scm do
    deprec2.mkdir(File.dirname(tracd_pidfile))
  end
  
  task :create_parent_dir, :roles => :scm do
    deprec2.mkdir(tracd_parent_dir, :via => :sudo)
  end
    
end end
  
end