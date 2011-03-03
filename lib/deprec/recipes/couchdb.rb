# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :couchdb do
      
      set :couchdb_user, 'couchdb'
      
      SRC_PACKAGES[:couchdb] = {
        :url => "http://mirror.public-internet.co.uk/ftp/apache/incubator/couchdb/0.8.0-incubating/apache-couchdb-0.8.0-incubating.tar.gz",
        :md5sum => "1f915929d4f54a2e0449a4a08f093118  git-1.6.1.tar.gz"
      }

      desc "Install CouchDB"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:couchdb], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:couchdb], src_dir)
        create_user
        setup_filepaths
        activate
        start
      end

      task :create_user, :roles => :couchdb do
        deprec2.useradd(couchdb_user)
      end
      
      task :setup_filepaths, :roles => :couchdb do
        sudo "mkdir -p /usr/local/var/lib/couchdb"
        sudo "chown -R couchdb /usr/local/var/lib/couchdb"
        sudo "mkdir -p /usr/local/var/log/couchdb"
        sudo "chown -R couchdb /usr/local/var/log/couchdb"
        sudo "mkdir -p /usr/local/var/run"
        sudo "chown -R couchdb /usr/local/var/run"
        sudo "cp /usr/local/etc/init.d/couchdb /etc/init.d/"
      end

      # Install dependencies for CouchDB
      task :install_deps, :roles => :couchdb do
        apt.install( {:base => %w(automake autoconf libtool subversion-tools help2man erlang libicu38 libicu-dev libreadline5-dev checkinstall libmozjs-dev)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:couchdb] = []
       
      desc "Generate CouchDB configs (system & project level)."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:couchdb].each do |file|
          deprec2.render_template(:couchdb, file)
        end
      end

      desc "Push CouchDB config files (system & project level) to server"
      task :config, :roles => :couchdb do
        deprec2.push_configs(:couchdb, SYSTEM_CONFIG_FILES[:couchdb])
      end
      
      desc "Set CouchDB to start on boot"
      task :activate, :roles => :couchdb do
        send(run_method, "update-rc.d couchdb defaults")
      end
      
      desc "Set CouchDB to not start on boot"
      task :deactivate, :roles => :couchdb do
        send(run_method, "update-rc.d -f couchdb remove")
      end
      
      desc "Start CouchDB"
      task :start, :roles => :web do
        send(run_method, "/etc/init.d/couchdb start")
      end

      desc "Stop CouchDB"
      task :stop, :roles => :web do
        send(run_method, "/etc/init.d/couchdb stop")
      end

      desc "Restart CouchDB"
      task :restart, :roles => :web do
        send(run_method, "/etc/init.d/couchdb restart")
      end

      desc "Reload CouchDB"
      task :reload, :roles => :web do
        send(run_method, "/etc/init.d/couchdb force-reload")
      end
      
    end
    
  end
end

# sudo apt-get install automake autoconf libtool subversion-tools help2man build-essential erlang libicu38 libicu-dev libreadline5-dev checkinstall libmozjs-dev wget
# wget http://mirror.public-internet.co.uk/ftp/apache/incubator/couchdb/0.8.0-incubating/apache-couchdb-0.8.0-incubating.tar.gz
# tar -xzvf apache-couchdb-0.8.0-incubating.tar.gz
# cd apache-couchdb-0.8.0-incubating
# ./configure
# make && sudo make install
# sudo useradd couchdb
# sudo mkdir -p /usr/local/var/lib/couchdb
# sudo chown -R couchdb /usr/local/var/lib/couchdb
# sudo mkdir -p /usr/local/var/log/couchdb
# sudo chown -R couchdb /usr/local/var/log/couchdb
# sudo mkdir -p /usr/local/var/run
# sudo chown -R couchdb /usr/local/var/run
# sudo cp /usr/local/etc/init.d/couchdb /etc/init.d/
# sudo update-rc.d couchdb defaults
# sudo /etc/init.d/couchdb start