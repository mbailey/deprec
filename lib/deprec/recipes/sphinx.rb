# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :sphinx do
      
      SRC_PACKAGES[:sphinx] = {
        :filename => 'sphinx-0.9.8-rc2.tar.gz',   
        :dir => 'sphinx-0.9.8-rc2',  
        :url => "http://www.sphinxsearch.com/downloads/sphinx-0.9.8-rc2.tar.gz",
        :unpack => "tar zxf sphinx-0.9.8-rc2.tar.gz;",
        :configure => %w(
          ./configure
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }
      
      desc "install Sphinx Search Engine"
      task :install do
        deprec2.download_src(SRC_PACKAGES[:sphinx], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:sphinx], src_dir)
      end
    
      # install dependencies for sphinx
      task :install_deps do
        # apt.install( {:base => %w(blah)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:sphinx] = []
      
      PROJECT_CONFIG_FILES[:sphinx] = [

        {:template => 'monit.conf.erb',
         :path => 'monit.conf',
         :mode => 0644,
         :owner => 'root:root'}
      
      ]

      desc <<-DESC
      Generate sphinx config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        PROJECT_CONFIG_FILES[:sphinx].each do |file|
          deprec2.render_template(:sphinx, file)
        end
      end

      desc "Push sphinx config files to server"
      task :config, :roles => :sphinx do
        config_project
      end
      
      desc "Push sphinx config files to server"
      task :config_project, :roles => :sphinx do
        deprec2.push_configs(:sphinx, PROJECT_CONFIG_FILES[:sphinx])
        symlink_monit_config
      end
      
      task :symlink_monit_config, :roles => :sphinx do
        sudo "ln -sf #{deploy_to}/sphinx/monit.conf #{monit_confd_dir}/sphinx_#{application}.conf"
      end


      # Control
      
      desc "Restart the sphinx searchd daemon"
      task :restart, :roles => :app do
        run("cd #{deploy_to}/current; /usr/bin/rake us:start")  ### start or restart?  SUDO ? ###
      end

      desc "Regenerate / Rotate the search index."
      task :reindex, :roles => :app do
        run("cd #{deploy_to}/current; /usr/bin/rake us:in")  ### SUDO ? ###
      end

    end 
  end
end