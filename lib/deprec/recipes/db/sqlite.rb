# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :sqlite do

      SRC_PACKAGES[:sqlite] = {
        :url => "http://www.sqlite.org/sqlite-amalgamation-3.7.2.tar.gz",
        :md5sum => "bd9586208f48ba840467bcfd066a6fa9  sqlite-amalgamation-3.7.2.tar.gz",
        :dir => 'sqlite-3.7.2'
      }


      desc "Install sqlite"
      task :install, :roles => :db do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:sqlite], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:sqlite], src_dir)
        gem2.install "sqlite3-ruby"
      end

      # install dependencies for nginx
      task :install_deps, :roles => :db do
        # apt.install( {:base => %w(blah)}, :stable )
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
