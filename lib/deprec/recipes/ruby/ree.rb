# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do

      set :ree_install_dir, "/usr/local"
      
      SRC_PACKAGES[:ree] = {
        :md5sum => "14d18635e238c8e37b51b2dd57891925  ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb",
        :url => "http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb",
        :download_method => :deb
      }
 
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        gem2.update_system # Install latest rubygems
      end
      
      task :install_deps do
        # not required with new deb package?
        # apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
    end
    
  end
end
