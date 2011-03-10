# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  # XXX not complete
  namespace :deprec do
    namespace :postfix do
      
      set(:postfix_relayhost) { Capistrano::CLI.ui.ask "What host should we relay mail through?" } 
      
      desc "Install Postfix"
      task :install, :roles => :mail do
        install_deps
      end
      
      # Install dependencies for Postfix
      task :install_deps, :roles => :mail do
        # mutt and mailutils are useful tools for testing mail
        # e.g. echo test | mail test@gmail.com
        apt.install( {:base => %w(postfix mutt mailutils)}, :stable )
      end
      
      # This is my default Postfix setup on servers that 
      # aren't my main outgoing mailserver.
      # It accepts mail from localhost only and relays
      # all mail to a master mailserver for delivery.
      #
      SYSTEM_CONFIG_FILES[:postfix] = [
        
        {:template => "main.cf.erb",
         :path => '/etc/postfix/main.cf',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "master.cf.erb",
         :path => '/etc/postfix/master.cf',
         :mode => 0644,
         :owner => 'root:root'},
          
         {:template => "dynamicmaps.cf.erb",
          :path => '/etc/postfix/dynamicmaps.cf',
          :mode => 0644,
          :owner => 'root:root'},
          
         {:template => "aliases.erb",
          :path => '/etc/aliases',
          :mode => 0644,
          :owner => 'root:root'}
         
      ]
      
      desc 'Generate configuration files(s) for postfix' 
      task :config_gen do
        SYSTEM_CONFIG_FILES[:postfix].each do |file|
          deprec2.render_template(:postfix, file)
        end
      end
      
      desc 'Deploy configuration files(s) for postfix' 
      task :config, :roles => :mail, :except => { :master => true } do
        deprec2.push_configs(:postfix, SYSTEM_CONFIG_FILES[:postfix])
        send(run_method, "/usr/bin/newaliases")
        reload
      end
      
      desc "Start Postfix"
      task :start, :roles => :mail, :except => { :master => true } do
        send(run_method, "/etc/init.d/postfix start")
      end

      desc "Stop Postfix"
      task :stop, :roles => :mail, :except => { :master => true } do
        send(run_method, "/etc/init.d/postfix stop")
      end

      desc "Restart Postfix"
      task :restart, :roles => :mail, :except => { :master => true } do
        send(run_method, "/etc/init.d/postfix restart")
      end

      desc "Reload Postfix"
      task :reload, :roles => :mail, :except => { :master => true } do
        send(run_method, "/etc/init.d/postfix reload")
      end
      
      task :activate, :roles => :web do
      end  
      
      task :deactivate, :roles => :web do
      end
      
      task :backup, :roles => :web do
      end
      
      task :restore, :roles => :web do
      end
      
    end
  end
end
      
      
      # Capistrano::Configuration.instance(:must_exist).load do 
# 
#   namespace :deprec do namespace :nginx do
#       
#   #Craig: I've kept this generic rather than calling the task setup postfix. 
#   # if people want other smtp servers, it could be configurable
#   desc "install and configure postfix"
#   task :setup_smtp_server do
#     install_postfix
#     set :postfix_destination_domains, [domain] + apache_server_aliases
#     deprec.render_template_to_file('postfix_main', '/etc/postfix/main.cf')
#   end
# 
#   end end
# end
