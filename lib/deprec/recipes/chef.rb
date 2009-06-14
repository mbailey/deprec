# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :chef do
      
      desc "Install Chef"
      task :install do
        install_deps
        sudo "gem sources -a http://gems.opscode.com"
        sudo "gem install ohai chef --source http://gems.opscode.com"
      end
      
      # Install dependencies for Chef
      task :install_deps, :roles => :chef do
        top.deprec.couchdb.install
        # top.deprec.ruby.install # XXX can we put this back in?
        apt.install( {:base => %w(ruby ruby1.8-dev libopenssl-ruby1.8 rdoc ri irb)}, :stable )
        top.deprec.rubygems.install
      end
      
      SYSTEM_CONFIG_FILES[:chef] = []
       
      desc "Generate Chef configs (system & project level)."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:chef].each do |file|
          deprec2.render_template(:chef, file)
        end
      end

      desc "Push Chef config files (system & project level) to server"
      task :config, :roles => :chef do
        deprec2.push_configs(:integrity, SYSTEM_CONFIG_FILES[:integrity])
        sudo "chown #{integrity_user} #{integrity_install_dir}/config.ru"
        activate
      end
      
      desc "Set Chef to start on boot"
      task :activate, :roles => :chef do
        send(run_method, "update-rc.d chef defaults")
      end
      
      desc "Set Chef to not start on boot"
      task :deactivate, :roles => :chef do
        send(run_method, "update-rc.d -f chef remove")
      end
      
      desc "Start Chef"
      task :start, :roles => :web do
        send(run_method, "/etc/init.d/chef start")
      end

      desc "Stop Chef"
      task :stop, :roles => :web do
        send(run_method, "/etc/init.d/chef stop")
      end

      desc "Restart Chef"
      task :restart, :roles => :web do
        send(run_method, "/etc/init.d/chef restart")
      end

      desc "Reload Chef"
      task :reload, :roles => :web do
        send(run_method, "/etc/init.d/chef force-reload")
      end
      
    end
    
  end
end
