# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :apache do
      
      desc "Install apache"
      task :install do
        install_deps
        enable_mod_rewrite
      end
      
      # install dependencies for apache
      task :install_deps do
        apt.install( {:base => %w(apache2-mpm-prefork apache2-prefork-dev rsync)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:apache] = [
        # They're generated and put in place during install
        # I may put them in here at some point
      ]

      PROJECT_CONFIG_FILES[:apache] = [
        # Not required
      ]

      desc "Generate configuration file(s) for apache from template(s)"
      task :config_gen do
        config_gen_system
      end

      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end

      task :config_gen_project do
        PROJECT_CONFIG_FILES[:apache].each do |file|
          deprec2.render_template(:apache, file)
        end
      end
      
      desc "Push apache config files to server"
      task :config, :roles => :web do
        deprec2.push_configs(:apache, SYSTEM_CONFIG_FILES[:apache])
      end
      
      # Stub so generic tasks don't fail (e.g. deprec:web:config_project)
      task :config_project do
      end
      
      task :enable_mod_rewrite, :roles => :web do
        sudo "a2enmod rewrite"
      end

      desc "Start Apache"
      task :start, :roles => :web do
        send(run_method, "/etc/init.d/apache2 start")
      end

      desc "Stop Apache"
      task :stop, :roles => :web do
        send(run_method, "/etc/init.d/apache2 stop")
      end

      desc "Restart Apache"
      task :restart, :roles => :web do
        send(run_method, "/etc/init.d/apache2 restart")
      end

      desc "Reload Apache"
      task :reload, :roles => :web do
        send(run_method, "/etc/init.d/apache2 force-reload")
      end

      desc "Set apache to start on boot"
      task :activate, :roles => :web do
        send(run_method, "update-rc.d apache2 defaults")
      end
      
      desc "Set apache to not start on boot"
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f apache2 remove")
      end
      
      task :backup, :roles => :web do
        # not yet implemented
      end
      
      task :restore, :roles => :web do
        # not yet implemented
      end

      # Generate an index.html page  
      task :install_index_page do
        std.su_put deprec2.render_template(:apache, :template => 'index.html.erb'), File.join('/var/www/index.html')
        std.su_put deprec2.render_template(:apache, :template => 'master.css'), File.join('/var/www/master.css')
      end
      
    end
  end
end