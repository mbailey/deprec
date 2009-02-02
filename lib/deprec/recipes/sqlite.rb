# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :sqlite do

      desc "Install sqlite"
      task :install, :roles => :db do
        install_deps
        gem2.install "sqlite3-ruby"
      end

      # install dependencies for nginx
      task :install_deps, :roles => :db do
        apt.install( {:base => %w(sqlite3 libsqlite3-ruby libsqlite3-dev)}, :stable )
      end
    end
    
    desc "Create a PostgreSQL user"
    task :create_user do
      # Not needed for sqlite
      # We need these stubs for deprec:rails:setup_database
    end
    
    desc "Create a PostgreSQL Database" 
    task :create_database do
      # Not needed for sqlite
      # We need these stubs for deprec:rails:setup_database
    end
    
    desc "Grant user access to Database" 
    task :grant_user_access_to_database do
      # Not needed for sqlite
      # We need these stubs for deprec:rails:setup_database
    end
    
  end
end