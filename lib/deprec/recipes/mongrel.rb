# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :deprec do
    namespace :mongrel do
        
      set :mongrel_servers, 2
      set :mongrel_port, 8000
      set :mongrel_address, "127.0.0.1"
      set(:mongrel_environment) { rails_env }
      set(:mongrel_log_dir) { "#{deploy_to}/shared/log" }
      set(:mongrel_pid_dir) { "#{deploy_to}/shared/pids" }
      set :mongrel_conf_dir, '/etc/mongrel_cluster'
      set(:mongrel_conf) { "/etc/mongrel_cluster/#{application}.yml" }  
      set :mongrel_user_prefix,  'mongrel_'
      set(:mongrel_user) { mongrel_user_prefix + application }
      set :mongrel_group_prefix,  'app_'
      set(:mongrel_group) { mongrel_group_prefix + application }

      
      # Install 
      
      desc "Install mongrel"
      task :install, :roles => :app do
        gem2.install 'mongrel'
        gem2.install 'mongrel_cluster'
        gem2.install 'swiftiply'
        symlink_mongrel_rails
        SYSTEM_CONFIG_FILES[:mongrel].each do |file|
          deprec2.render_template(:mongrel, file.merge(:remote=>true))
        end
        activate_system
      end
      
      task :symlink_mongrel_rails, :roles => :app do
        sudo "ln -sf /usr/local/bin/mongrel_rails /usr/bin/mongrel_rails"
      end
      
      task :symlink_logrotate_config, :roles => :app do
        sudo "ln -sf #{deploy_to}/mongrel/logrotate.conf /etc/logrotate.d/mongrel-#{application}"
      end
    
      # Configure
      
      SYSTEM_CONFIG_FILES[:mongrel] = [

        {:template => 'mongrel_cluster-init-script',
         :path => '/etc/init.d/mongrel_cluster',
         :mode => 0755,
         :owner => 'root:root'}
      
      ]
        
      PROJECT_CONFIG_FILES[:mongrel] = [

        {:template => 'mongrel_cluster.yml.erb',
         :path => 'cluster.yml',
         :mode => 0644,
         :owner => 'root:root'},

        {:template => 'monit.conf.erb',
         :path => "monit.conf", 
         :mode => 0600,
         :owner => 'root:root'},
         
        {:template => 'logrotate.conf.erb',
         :path => "logrotate.conf", 
         :mode => 0644,
         :owner => 'root:root'}
      
      ]
       
      desc "Generate configuration file(s) for mongrel from template(s)"
      task :config_gen do
        config_gen_system
        config_gen_project
      end
      
      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:mongrel].each do |file|
          deprec2.render_template(:mongrel, file)
        end  
      end
      
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:mongrel].each do |file|
          deprec2.render_template(:mongrel, file)
        end  
      end
      
      desc 'Deploy configuration files(s) for mongrel' 
      task :config, :roles => :app do
        config_system
        config_project
      end
      
      task :config_system, :roles => :app do
        deprec2.push_configs(:mongrel, SYSTEM_CONFIG_FILES[:mongrel])
      end
      
      task :config_project, :roles => :app do
        create_mongrel_user_and_group
        deprec2.push_configs(:mongrel, PROJECT_CONFIG_FILES[:mongrel])
        symlink_mongrel_cluster
        symlink_monit_config
        symlink_logrotate_config
      end
      
      task :symlink_monit_config, :roles => :app do
        deprec2.mkdir(monit_confd_dir, :via => :sudo)
        sudo "ln -sf #{deploy_to}/mongrel/monit.conf #{monit_confd_dir}/mongrel_#{application}.conf"
      end
      
      task :unlink_monit_config, :roles => :app do
        sudo "test -L #{monit_confd_dir}/mongrel_#{application}.conf && unlink #{monit_confd_dir}/mongrel_#{application}.conf"
      end
      
      task :symlink_mongrel_cluster, :roles => :app do
        deprec2.mkdir(mongrel_conf_dir, :via => :sudo)
        sudo "ln -sf #{deploy_to}/mongrel/cluster.yml #{mongrel_conf}"
      end
      
      task :unlink_mongrel_cluster, :roles => :app do
        sudo "test -L #{mongrel_conf} && unlink #{mongrel_conf}"
      end
      
      
      # Control
      
      desc "Start application server."
      task :start, :roles => :app do
        send(run_method, "mongrel_rails cluster::start --clean -C #{mongrel_conf}")
      end
      
      desc "Stop application server."
      task :stop, :roles => :app do
        send(run_method, "mongrel_rails cluster::stop -C #{mongrel_conf}")
      end
      
      desc "Restart application server."
      task :restart, :roles => :app do
        send(run_method, "mongrel_rails cluster::restart --clean -C #{mongrel_conf}")
      end
      
      task :activate do
        activate_system        
        activate_project
      end  
      
      task :activate_system do
        send(run_method, "update-rc.d mongrel_cluster defaults")
      end
      
      task :activate_project do
        symlink_mongrel_cluster
        symlink_monit_config
      end
      
      task :deactivate, :roles => :app do
        puts
        puts "******************************************************************"
        puts
        puts "Danger!"
        puts
        puts "Do you want to deactivate just this project or all mongrel"
        puts "clusters on this server? Try a more granular command:"
        puts
        puts "cap deprec:mongrel:deactivate_system  # disable all clusters"
        puts "cap deprec:mongrel:deactivate_project # disable only this project"
        puts
        puts "******************************************************************"
        puts
      end
      
      task :deactivate_system, :roles => :app do
        send(run_method, "update-rc.d -f mongrel_cluster remove")
      end
      
      task :deactivate_project, :roles => :app do
        unlink_mongrel_cluster
        unlink_monit_config
        restart
      end
      
      task :backup, :roles => :app do
      end
      
      task :restore, :roles => :app do
      end
      
      desc "create user and group for mongel to run as"
      task :create_mongrel_user_and_group, :roles => :app do
        deprec2.groupadd(mongrel_group) 
        deprec2.useradd(mongrel_user, :group => mongrel_group, :homedir => false)
        # Set the primary group for the mongrel user (in case user already existed
        # when previous command was run)
        sudo "usermod --gid #{mongrel_group} #{mongrel_user}"
      end
      
      desc "set group ownership and permissions on dirs mongrel needs to write to"
      task :set_perms_for_mongrel_dirs, :roles => :app do
        tmp_dir = "#{deploy_to}/current/tmp"
        shared_dir = "#{deploy_to}/shared"
        files = ["#{mongrel_log_dir}/mongrel.log", "#{mongrel_log_dir}/#{rails_env}.log"]

        sudo "chgrp -R #{mongrel_group} #{tmp_dir} #{shared_dir}"
        sudo "chmod -R g+w #{tmp_dir} #{shared_dir}" 
        # set owner and group of log files 
        files.each { |file|
          sudo "touch #{file}"
          sudo "chown #{mongrel_user} #{file}"   
          sudo "chgrp #{mongrel_group} #{file}" 
          sudo "chmod g+w #{file}"   
        } 
      end
      
    end
  end
end
