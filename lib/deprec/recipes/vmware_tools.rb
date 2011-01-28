# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :vmware_tools do

      desc "Install VMware tools on guest" 
      task :install do
        run "#{sudo} mount /dev/cdrom /mnt"
        run "tar zxfv /mnt/VMwareTools-*.tar.gz"
        run "#{sudo} ./vmware-tools-distrib/vmware-install.pl --default"
      end

    end
  end
end
