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
    
  end
end