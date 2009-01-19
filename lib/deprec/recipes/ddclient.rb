# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ddclient do
      
      set(:ddclient_user) { Capistrano::CLI.ui.ask "Enter ddclient username" }
      set(:ddclient_pass) { Capistrano::CLI.ui.ask "Enter ddclient password" }
      set(:ddclient_domains) { Capistrano::CLI.ui.ask "Enter ddclient domain" }
      set(:ddclient_interface) { 
        Capistrano::CLI.ui.ask "Enter ddclient interface" do |q|
          q.default = 'eth0'
        end 
      }
      
      desc "Install ddclient"
      task :install do
        install_deps
      end
      
      # install dependencies for ddclient
      task :install_deps do
        apt.install( {:base => %w(ddclient)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:ddclient] = [
        { :template => "ddclient.conf.erb",
          :path => '/etc/ddclient.conf',
          :mode => 0600,
          :owner => 'root:root'},
          
        { :template => "ddclient.erb",
          :path => '/etc/default/ddclient',
          :mode => 0600,
          :owner => 'root:root'}
      ]
      
      desc "Update system networking configuration"
      task :config do
        SYSTEM_CONFIG_FILES[:ddclient].each do |file|
          deprec2.render_template(:ddclient, file.merge(:remote=>true))
        end
        start
      end
      
      task :start do
        sudo '/etc/init.d/ddclient start'
      end
      
    end
  end
end