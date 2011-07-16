# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :bash do

      SYSTEM_CONFIG_FILES[:bash] = [
        
        {:template => "bash_global",
         :path => '.bash_global',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      task :config_gen do        
        SYSTEM_CONFIG_FILES[:bash].each do |file|
          deprec2.render_template(:bash, file)
        end
      end
      
      desc "Push bash config files to server"
      task :config do
        deprec2.push_configs(:bash, SYSTEM_CONFIG_FILES[:bash].collect{|file| file.merge(:owner => user)})
        deprec2.append_to_file_if_missing('.bashrc', '. ~/.bash_global')
      end

    end
  end
end
