# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  set :database_yml_in_scm, true
  set :app_symlinks, nil
  set :rails_env, 'production'
  set :gems_for_project, nil # Array of gems to be installed for app
  set :shared_dirs, nil # Array of directories that should be created under shared/
                        # and linked to in the project

  # Hook into the default capistrano deploy tasks
  before 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_user_perms
    top.deprec.rails.setup_paths
    top.deprec.rails.setup_shared_dirs
    top.deprec.rails.install_gems_for_project
  end

  after 'deploy:setup', :except => { :no_release => true } do
    top.deprec.rails.setup_servers
    top.deprec.rails.create_config_dir
    top.deprec.rails.set_perms_on_shared_and_releases
  end

  after 'deploy:symlink', :roles => :app do
    top.deprec.rails.symlink_shared_dirs
    top.deprec.rails.symlink_database_yml unless database_yml_in_scm
    top.deprec.mongrel.set_perms_for_mongrel_dirs
  end

  after :deploy, :roles => :app do
    deploy.cleanup
  end

  namespace :deprec do
    namespace :rails do
      
      task :install, :roles => :app do
        install_deps
        install_gems
      end

      task :install_deps do
        apt.install( {:base => %w(libmysqlclient15-dev sqlite3 libsqlite3-ruby libsqlite3-dev)}, :stable )
      end
      
      # install some required ruby gems
      task :install_gems do
        gem2.install 'sqlite3-ruby'
        gem2.install 'mysql'
        gem2.install 'rails'
        gem2.install 'rspec'
      end
      
      desc <<-DESC
      Install full rails stack on a stock standard ubuntu server (7.10, 8.04)
      DESC
      task :install_stack do   
        
        # Ruby everywhere!
        top.deprec.ruby.install      
        top.deprec.rubygems.install
        
        top.deprec.nginx.install        
        
        # XXX check this out before removing - Mike
        deprec2.for_roles('app') do
          top.deprec.svn.install
          top.deprec.git.install     
          top.deprec.mongrel.install
          top.deprec.monit.install
          top.deprec.rails.install
        end
        
        top.deprec.logrotate.install        
        
        top.deprec.mysql.install
        top.deprec.mysql.start      

      end
      
      task :install_rails_stack do
        puts "deprecated: this task is now called install_stack"
        install_stack
      end
      
      task :install_gems_for_project, :roles => :app do
          if gems_for_project
            gems_for_project.each { |gem| gem2.install(gem) }
          end
      end

      PROJECT_CONFIG_FILES[:nginx] = [
      
        {:template => 'rails_nginx_vhost.conf.erb',
         :path => "rails_nginx_vhost.conf", 
         :mode => 0644,
         :owner => 'root:root'},
           
        {:template => 'logrotate.conf.erb',
         :path => "logrotate.conf", 
         :mode => 0644,
         :owner => 'root:root'}  
      ]
      
      desc "Generate config files for rails app."
      task :config_gen do
        PROJECT_CONFIG_FILES[:nginx].each do |file|
          deprec2.render_template(:nginx, file)
        end
        top.deprec.mongrel.config_gen_project
      end

      desc "Push out config files for rails app."
      task :config, :roles => [:app, :web] do
        deprec2.push_configs(:nginx, PROJECT_CONFIG_FILES[:nginx])
        top.deprec.mongrel.config_project
        symlink_nginx_vhost
        symlink_nginx_logrotate_config
      end

      task :symlink_nginx_vhost, :roles => :web do
        sudo "ln -sf #{deploy_to}/nginx/rails_nginx_vhost.conf #{nginx_vhost_dir}/#{application}.conf"
      end
      
      task :symlink_nginx_logrotate_config, :roles => :web do
        sudo "ln -sf #{deploy_to}/nginx/logrotate.conf /etc/logrotate.d/nginx-#{application}"
      end

      task :create_config_dir, :roles => :app do
        deprec2.mkdir("#{shared_path}/config", :group => group, :mode => 0775, :via => :sudo)
      end
      
      desc "Create deployment group and add current user to it"
      task :setup_user_perms, :roles => [:app, :web] do
        deprec2.groupadd(group)
        deprec2.add_user_to_group(user, group)
        deprec2.groupadd(mongrel_group)
        deprec2.add_user_to_group(user, mongrel_group)
        # we've just added ourself to a group - need to teardown connection
        # so that next command uses new session where we belong in group 
        deprec2.teardown_connections
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
            run "ln -nfs #{shared_path}/#{dir} #{current_path}/#{dir}" 
          end
        end
      end
      
      # desc "Symlink shared files."
      # task :symlink_shared_files, :roles => [:app, :web] do
      #   if shared_files
      #     shared_files.each { |file| run "ln -nfs #{shared_path}/#{file} #{current_path}/#{file}" }
      #   end
      # end

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
        run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
      end


      
      desc "setup and configure servers"
      task :setup_servers do
        top.deprec.nginx.activate       
        top.deprec.mongrel.create_mongrel_user_and_group 
        top.deprec.mongrel.activate
        top.deprec.monit.activate
        top.deprec.rails.config_gen
        top.deprec.rails.config
      end
    end

    namespace :db do
      
      desc "Create database"
      task :create, :roles => :db do
        run "cd #{deploy_to}/current && rake db:create RAILS_ENV=#{rails_env}"
      end

      desc "Run database migrations"
      task :migrate, :roles => :db do
        run "cd #{deploy_to}/current && rake db:migrate RAILS_ENV=#{rails_env}"
      end
      
      desc "Run database migrations"
      task :schema_load, :roles => :db do
        run "cd #{deploy_to}/current && rake db:schema:load RAILS_ENV=#{rails_env}"
      end

      desc "Roll database back to previous migration"
      task :rollback, :roles => :db do
        run "cd #{deploy_to}/current && rake db:rollback RAILS_ENV=#{rails_env}"
      end

    end

  end
  
end
