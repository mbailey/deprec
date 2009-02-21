# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ubuntu do

      desc "apt-get update. Resynchronize the package index files from their sources."
      task :update do
        apt.update
      end
      
      desc "apt-get upgrade. Install the newest versions of all packages currently
                 installed on the system from the sources enumerated in /etc/apt/sources.list.."
      task :upgrade do
        apt.upgrade
      end
      
      desc "reboot the server"
      task :restart do
        sudo "reboot"
      end
      
      desc "shut down the server"
      task :shutdown do
        sudo "shutdown -h now"
      end
      
    end
  end
end
