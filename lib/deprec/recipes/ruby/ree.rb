# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do

      set :ree_install_dir, "/usr/local"
      
      SRC_PACKAGES[:ree] = {
        :md5sum => "0eaff4bcd0bc9fa310c593be7ae33937  ruby-enterprise_1.8.7-2010.02_amd64_ubuntu8.04.deb",
        :url => "http://rubyforge.org/frs/download.php/71097/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu8.04.deb",
        :download_method => :deb
      }
 
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        gem2.update_system # Install latest rubygems
      end
      
      task :install_deps do
        # not required with new dev package?
        # apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
    end
    
  end
end
