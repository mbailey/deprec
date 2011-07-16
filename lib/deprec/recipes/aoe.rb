# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  SRC_PACKAGES[:aoe] = {
    :url => "http://support.coraid.com/support/linux/aoe6-64.tar.gz",
    :md5sum => "c5e1ebb734e3b29c0a3d886a700ca44a  aoe6-64.tar.gz",
    :configure => ''
  }
  
  SRC_PACKAGES[:cec] = {
    :url => "http://easynews.dl.sourceforge.net/sourceforge/aoetools/cec-8.tgz",
    :md5sum => "7899dc549f9a368e532f9c39ed819f71  cec-8.tgz",
    :configure => '',
    :install => "test -f /usr/sbin/cec && rm /usr/sbin/cec; make install;"
  }
  
  SRC_PACKAGES[:ddt] = {
    :url => "http://support.coraid.com/support/sr/ddt-8.tgz",
    :md5sum => "256a58aba5e05f9995fb9de6aadadf92  ddt-8.tgz",
    :configure => ''
  }
  
  SRC_PACKAGES[:aoemask] = {
    :url => "http://support.coraid.com/support/sr/aoemask-1.tgz",
    :md5sum => "379461a28d511e269f4593b846bd1288  aoemask-1.tgz"
  }
    
  namespace :deprec do
    namespace :aoe do
      
      desc "Install aoe drivers required to mount Coraid block devices"
      task :install, :roles => :aoe do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:aoe], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:aoe], src_dir)
      end

      task :install_deps, :roles => :aoe do
        apt.install( {:base => %w(build-essential linux-headers-$(uname -r) vblade aoetools)}, :stable )
      end
      
      desc "Install all AoE related software"
      task :install_all, :roles => :aoe do
        top.deprec.aoe.install
        top.deprec.cec.install
        top.deprec.ddt.install
        top.deprec.aoemask.install
      end
      
    end

    namespace :cec do
      desc "install CEC (Coraid Ethernet Console)"
      task :install, :roles => :aoe do
        deprec2.download_src(SRC_PACKAGES[:cec], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:cec], src_dir)
      end
    end
    
    namespace :ddt do
      desc "install DDT (tool for testing performance)"
      task :install, :roles => :aoe do
        deprec2.download_src(SRC_PACKAGES[:ddt], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ddt], src_dir)
      end
    end
    
    namespace :aoemask do
      desc "install aoemask"
      task :install, :roles => :aoe do
        deprec2.download_src(SRC_PACKAGES[:aoemask], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:aoemask], src_dir)
      end
    end
        
  end
  
end


