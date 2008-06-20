# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ubuntu do
      
      task :update do
        apt.update
      end
      
      task :upgrade do
        apt.upgrade
      end
      
      task :restart do
        sudo "reboot"
      end
      
    end
  end
end