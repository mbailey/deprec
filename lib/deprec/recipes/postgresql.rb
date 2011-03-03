# Copyright 2006-2008 by Saulius Grigaitis. All rights reserved.
# Backported from centostrano to deprec by Eric Harris-Braun.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :postgresql do
      
      # Installation
      desc "Install postgresql"
      task :install, :roles => :db do
        install_deps
      end
      
      # Install dependencies for PostgreSQL 
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(postgresql postgresql-client libpq-dev)}, :stable ) 
      end
       
      # Configuration
      
      SYSTEM_CONFIG_FILES[:postgresql] = [
        
        {:template => "pg_hba.conf.erb",
         :path => '/var/lib/pgsql/data/pg_hba.conf',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      desc "Generate configuration file(s) for postgresql from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:postgresql].each do |file|
          deprec2.render_template(:postgresql, file)
        end
      end
      
      desc "Push postgresql config files to server"
      task :config, :roles => :db do
        deprec2.push_configs(:postgresql, SYSTEM_CONFIG_FILES[:postgresql])
      end
      
      task :activate, :roles => :db do
        send(run_method, "update-rc.d postgresql-8.3 defaults")
      end  
      
      task :deactivate, :roles => :db do
        send(run_method, "update-rc.d -f postgresql-8.3 remove")
      end
      
      # Control
      
      desc "Start PostgreSQL"
      task :start, :roles => :db do
        send(run_method, "/etc/init.d/postgresql-8.3 start")
      end
      
      desc "Stop PostgreSQL"
      task :stop, :roles => :db do
        send(run_method, "/etc/init.d/postgresql-8.3 stop")
      end
      
      desc "Restart PostgreSQL"
      task :restart, :roles => :db do
        send(run_method, "/etc/init.d/postgresql-8.3 restart")
      end
      
      desc "Reload PostgreSQL"
      task :reload, :roles => :db do
        send(run_method, "/etc/init.d/postgresql-8.3 reload")
      end
      
      task :backup, :roles => :db do
      end
      
      task :restore, :roles => :db do
      end
      
      desc "Create a PostgreSQL user"
      task :create_user, :roles => :db do
        cmd = "su - postgres -c \'createuser -P -D -A -E #{db_user}\'"
        sudo cmd do |channel, stream, data|
          if data =~ /^Enter password for new/
            channel.send_data "#{db_password}\n" 
          end
          if data =~ /^Enter it again:/
            channel.send_data "#{db_password}\n" 
          end
          if data =~ /^Shall the new role be allowed to create more new roles?/
            channel.send_data "n\n" 
          end
        end
      end
      
      desc "Create a PostgreSQL Database" 
      task :create_database, :roles => :db do
        sudo "su - postgres -c \'createdb -O #{db_user} #{db_name}\'"          
      end
      
      desc "Grant user access to Database" 
      task :grant_user_access_to_database, :roles => :db do
        # sudo "what's the command for this using #{db_user} #{db_name}\'"          
      end
            
    end
  end
end