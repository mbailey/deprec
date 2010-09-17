# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  set :app_user_prefix,  'app_'
  set(:app_user) { app_user_prefix + application }
  set :app_group_prefix,  'app_'
  set(:app_group) { app_group_prefix + application }
  set(:app_user_homedir) { deploy_to }
  set :database_yml_in_scm, true
  set :app_symlinks, nil
  set :rails_env, 'production'
  set :gems_for_project, nil # Array of gems to be installed for app
  set :packages_for_project, nil # Array of packages to be installed for app
  set :shared_dirs, nil # Array of directories that should be created under shared/
                        # and linked to in the project

  # Hook into the default capistrano deploy tasks
  before 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_user_perms
    top.deprec.rails.create_app_user_and_group
    top.deprec.rails.setup_paths
    top.deprec.rails.setup_shared_dirs
    top.deprec.rails.install_packages_for_project
    top.deprec.rails.install_gems_for_project
  end

  after 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.create_config_dir
    top.deprec.rails.config_gen
    top.deprec.rails.config
    top.deprec.rails.activate_services
    top.deprec.rails.set_perms_on_shared_and_releases
    top.deprec.web.reload
    top.deprec.rails.setup_database
  end

  after 'deploy:symlink', :roles => :app do
    top.deprec.rails.symlink_shared_dirs
    top.deprec.rails.symlink_database_yml unless database_yml_in_scm
    top.deprec.rails.make_writable_by_app
    top.deprec.passenger.set_owner_of_environment_rb if app_server_type.to_s == 'passenger'
  end

  after :deploy, "deploy:cleanup"
  
  namespace :deprec do
    namespace :rails do

      task :install, :roles => :app do
        install_deps
        gem2.install 'rails'
        gem2.install 'bundler'
      end

      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev sqlite3 libsqlite3-ruby libsqlite3-dev libpq-dev)}, :stable )
      end
      
      #
      # If database.yml is not kept in scm and it is present in local
      # config dir then push it out to server.
      #
      before 'deprec:rails:symlink_database_yml', :roles => :app do
        push_database_yml unless database_yml_in_scm
      end
      
      task :setup_database, :roles => :db do
        if ! roles[:db].servers.empty? # Some apps don't use database!
          deprec2.read_database_yml
          top.deprec.db.create_user
          top.deprec.db.create_database
          top.deprec.db.grant_user_access_to_database
        end
      end
      
      desc <<-DESC
      Install full rails stack on a stock standard ubuntu server (7.10, 8.04)
      DESC
      task :install_stack do   

        top.deprec.ruby.install
        top.deprec.rails.install
        top.deprec.svn.install
        top.deprec.git.install
        top.deprec.web.install        # Uses value of web_server_type 
        top.deprec.app.install        # Uses value of app_server_type
        top.deprec.monit.install
        top.deprec.logrotate.install  
        
        # We not longer install database server as part of this task.
        # There is too much danger that someone will wreck an existing
        # shared database.
        #
        # Install database server with:
        #
        #   cap deprec:db:install
      end
      
      task :install_rails_stack do
        puts "deprecated: this task is now called install_stack"
        install_stack
      end
      
      desc "Generate config files for rails app."
      task :config_gen do
        top.deprec.web.config_gen_project
        top.deprec.app.config_gen_project
      end

      desc "Push out config files for rails app."
      task :config do
        top.deprec.web.config_project
        top.deprec.app.config_project
      end

      task :create_config_dir, :roles => :app do
        deprec2.mkdir("#{shared_path}/config", :group => group, :mode => 0775, :via => :sudo)
      end
      
      # XXX This should be restricted a bit to limit what app can write to. - Mike
      desc "set group ownership and permissions on dirs app server needs to write to"
      task :make_writable_by_app, :roles => :app do
        dirs = "#{shared_path} #{current_path}/tmp #{current_path}/public"
        sudo "chgrp -R #{app_group} #{dirs}"
        sudo "chmod -R g+w #{dirs}" 
        
        # set owner and group of log files 
        # XXX Factor out mongrel
        files = ["#{mongrel_log_dir}/mongrel.log", "#{mongrel_log_dir}/#{rails_env}.log"]
        files.each { |file|
          sudo "touch #{file}"
          sudo "chown #{app_user} #{file}"   
          sudo "chgrp #{app_group} #{file}" 
          sudo "chmod g+w #{file}"   
        } 
      end
      
      desc "Create deployment group and add current user to it"
      task :setup_user_perms, :roles => [:app, :web] do
        deprec2.groupadd(group)
        deprec2.add_user_to_group(user, group)
        deprec2.groupadd(app_group)
        deprec2.add_user_to_group(user, app_group)
        # we've just added ourself to a group - need to teardown connection
        # so that next command uses new session where we belong in group 
        deprec2.teardown_connections
      end
      
      desc "Create user and group for application to run as"
      task :create_app_user_and_group, :roles => :app do
        deprec2.groupadd(app_group) 
        deprec2.useradd(app_user, :group => app_group, :homedir => false)
        # Set the primary group for the user the application runs as (in case 
        # user already existed when previous command was run)
        sudo "usermod --gid #{app_group} --home #{app_user_homedir} #{app_user}"
      end
      
      task :set_perms_on_shared_and_releases, :roles => :app do
        releases = File.join(deploy_to, 'releases')
        sudo "chgrp -R #{group} #{shared_path} #{releases}"
        sudo "chmod -R g+w #{shared_path} #{releases}"
      end

      # Setup database server.
      task :setup_db, :roles => :db, :only => { :primary => true } do
        top.deprec.mysql.setup
      end

      # setup extra paths required for deployment
      task :setup_paths, :roles => [:app, :web] do
        deprec2.mkdir(deploy_to, :mode => 0775, :group => group, :via => :sudo)
        deprec2.mkdir(shared_path, :mode => 0775, :group => group, :via => :sudo)
      end
      
      # Symlink list of files and dirs from shared to current
      #
      # XXX write up explanation
      #
      desc "Setup shared dirs"
      task :setup_shared_dirs, :roles => [:app, :web] do
        if shared_dirs
          shared_dirs.each { |dir| deprec2.mkdir( "#{shared_path}/#{dir}", :via => :sudo ) }
        end
      end
      #
      desc "Symlink shared dirs."
      task :symlink_shared_dirs, :roles => [:app, :web] do
        if shared_dirs
          shared_dirs.each do |dir| 
            path = File.split(dir)[0]
            if path != '.'
              deprec2.mkdir("#{current_path}/#{path}")
            end
            sudo "test -d #{current_path}/#{dir} && mv #{current_path}/#{dir} #{current_path}/#{dir}.moved_by_deprec; exit 0"
            run "ln -nfs #{shared_path}/#{dir} #{current_path}/#{dir}" 
          end
        end
      end
      
      task :install_packages_for_project, :roles => :app do
        if packages_for_project
          apt.install({ :base => packages_for_project }, :stable)
        end
      end
      
      task :install_gems_for_project, :roles => :app do
        if gems_for_project
          gems_for_project.each { |gem| gem2.install(gem) }
        end
      end
      
      desc "Activate web, app and monit"
      task :activate_services do
        top.deprec.web.activate       
        top.deprec.app.activate
        top.deprec.monit.activate
      end

      # database.yml stuff
      #
      # XXX DRY this up 
      # I don't know how to let :gen_db_yml check if values have been set.
      #
      # if (self.respond_to?("db_host_#{rails_env}".to_sym)) # doesn't seem to work

      set :db_host_default, lambda { Capistrano::CLI.prompt 'Enter database host', 'localhost'}
      set :db_host_staging, lambda { db_host_default }
      set :db_host_production, lambda { db_host_default }

      set :db_name_default, lambda { Capistrano::CLI.prompt 'Enter database name', "#{application}_#{rails_env}" }
      set :db_name_staging, lambda { db_name_default }
      set :db_name_production, lambda { db_name_default }

      set :db_user_default, lambda { Capistrano::CLI.prompt 'Enter database user', 'root' }
      set :db_user_staging, lambda { db_user_default }
      set :db_user_production, lambda { db_user_default }

      set :db_pass_default, lambda { Capistrano::CLI.prompt 'Enter database pass', '' }
      set :db_pass_staging, lambda { db_pass_default }
      set :db_pass_production, lambda { db_pass_default }

      set :db_adaptor_default, lambda { Capistrano::CLI.prompt 'Enter database adaptor', 'mysql' }
      set :db_adaptor_staging, lambda { db_adaptor_default }
      set :db_adaptor_production, lambda { db_adaptor_default }

      set :db_socket_default, lambda { Capistrano::CLI.prompt('Enter database socket', '')}
      set :db_socket_staging, lambda { db_socket_default }
      set :db_socket_production, lambda { db_socket_default }

      task :generate_database_yml, :roles => :app do    
        database_configuration = render :template => <<-EOF
        #{rails_env}:
        adapter: #{self.send("db_adaptor_#{rails_env}")}
        database: #{self.send("db_name_#{rails_env}")}
        username: #{self.send("db_user_#{rails_env}")}
        password: #{self.send("db_pass_#{rails_env}")}
        host: #{self.send("db_host_#{rails_env}")}
        socket: #{self.send("db_socket_#{rails_env}")}
        EOF
        run "mkdir -p #{deploy_to}/#{shared_dir}/config" 
        put database_configuration, "#{deploy_to}/#{shared_dir}/config/database.yml" 
      end

      desc "Link in the production database.yml" 
      task :symlink_database_yml, :roles => :app do
        run "#{sudo} ln -nfs #{shared_path}/config/database.yml #{current_path}/config/database.yml" 
      end
      
      desc "Copy database.yml to shared/config/database.yml. Useful if not kept in scm"
      task :push_database_yml, :roles => :app do
        stage = exists?(:stage) ? fetch(:stage).to_s : ''
        full_local_path = File.join('config', stage, 'database.yml')
        if File.exists?(full_local_path)
          std.su_put(File.read(full_local_path), "#{shared_path}/config/database.yml", '/tmp/')
        end
      end
      
    end

    namespace :database do
      
      desc "Create database"
      task :create, :roles => :app do
        run "cd #{deploy_to}/current && rake db:create RAILS_ENV=#{rails_env}"
      end

      desc "Run database migrations"
      task :migrate, :roles => :app do
        run "cd #{deploy_to}/current && rake db:migrate RAILS_ENV=#{rails_env}"
      end
      
      desc "Run database migrations"
      task :schema_load, :roles => :app do
        run "cd #{deploy_to}/current && rake db:schema:load RAILS_ENV=#{rails_env}"
      end

      desc "Roll database back to previous migration"
      task :rollback, :roles => :app do
        run "cd #{deploy_to}/current && rake db:rollback RAILS_ENV=#{rails_env}"
      end

    end

  end
  
end


