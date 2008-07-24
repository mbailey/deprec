# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  SRC_PACKAGES[:aoe] = {
    :filename => 'aoe6-56.tar.gz',   
    :md5sum => "93689aaad32f647a788c15c82bd0158e  aoe6-56.tar.gz", 
    :dir => 'aoe6-56',  
    :url => "http://www.coraid.com/support/linux/aoe6-56.tar.gz",
    :unpack => "tar zxf aoe6-56.tar.gz;",
    :make => 'make;',
    :install => 'make install;'
  }
    
  namespace :deprec do
    namespace :aoe do

      desc "Install aoe drivers required to mount Coraid block devices"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:aoe], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:aoe], src_dir)
      end

      task :install_deps do
        apt.install( {:base => %w(build-essential linux-headers-$(uname -r) vblade aoetools)}, :stable )
      end

    end

    
    SRC_PACKAGES[:cec] = {
      :url => "http://easynews.dl.sourceforge.net/sourceforge/aoetools/cec-8.tgz",
      :md5sum => "7899dc549f9a368e532f9c39ed819f71  cec-8.tgz"
    }
    
    namespace :cec do
  
      desc "install CEC (Coraid Ethernet Console)"
      task :install do
        deprec2.download_src(SRC_PACKAGES[:cec], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:cec], src_dir)
      end
      
    end
    
    SRC_PACKAGES[:ddt] = {
      :url => "http://support.coraid.com/support/sr/ddt-6.tgz",
      :md5sum => "5e1e8a58a8621b93440be605113f7bc0  ddt-6.tgz"
    }
    
    namespace :ddt do
  
      desc "install DDT (tool for testing performance)"
      task :install do
        deprec2.download_src(SRC_PACKAGES[:ddt], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ddt], src_dir)
      end
      
    end
    
    SRC_PACKAGES[:aoemask] = {
      :url => "http://support.coraid.com/support/sr/aoemask-1.tgz",
      :md5sum => "379461a28d511e269f4593b846bd1288  aoemask-1.tgz"
    }
    
    namespace :aoemask do
  
      desc "install aoemask"
      task :install do
        deprec2.download_src(SRC_PACKAGES[:aoemask], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:aoemask], src_dir)
      end
      
    end
        
  end
  
end


