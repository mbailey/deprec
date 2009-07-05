# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :chef do
      
      set(:server_fqdn) { Capistrano::CLI.ui.ask 'Enter Chef server hostname' }
      set(:recipes) { "chef::#{install_type}" }
      
      default(:install_type) do
        Capistrano::CLI.ui.choose do |menu| 
          %w(client server).each {|c| menu.choice(c)}
          menu.header = "Select Chef version to install"
        end
      end
      
      desc "Install Chef"
      task :install do
        config # Do this first so we can ensure we have any user input
        install_deps
        run_solo
        top.deprec.apache.restart if install_type == 'server'
      end
      
      desc "Run chef-solo to setup on server"
      task :run_solo do
        sudo 'chef-solo -c /etc/chef/solo.rb -j /etc/chef/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz'
      end
      
      # Install dependencies for Chef
      task :install_deps, :roles => :chef do
        top.deprec.couchdb.install if install_type == 'server'
        # apt.install( {:base => %w(ruby ruby1.8-dev libopenssl-ruby1.8 rdoc ri irb)}, :stable )
        top.deprec.ruby.install
        top.deprec.rubygems.install
        sudo "gem sources -a http://gems.opscode.com"
        sudo "gem install ohai chef --no-rdoc --no-ri"
      end
      
      SYSTEM_CONFIG_FILES[:chef] = [
        
        {:template => "solo.rb",
         :path => '/etc/chef/solo.rb',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "chef.json.erb",
         :path => '/etc/chef/chef.json',
         :mode => 0644,
         :owner => 'root:root'}
         
      ]
       
      desc "Generate Chef configs (system & project level)."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:chef].each do |file|
          deprec2.render_template(:chef, file)
        end
      end

      desc "Push Chef config files (system & project level) to server"
      task :config, :roles => :chef do
        deprec2.push_configs(:chef, SYSTEM_CONFIG_FILES[:chef])
      end
      
    end
    
  end
end
