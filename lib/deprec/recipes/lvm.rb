# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :lvm do
      
      task :pvdisplay do
        sudo "pvdisplay"
      end
      
      task :vgdisplay do
        sudo "vgdisplay"
      end
      
      task :lvdisplay do
        sudo "lvdisplay"
      end
      
    end
  end
end