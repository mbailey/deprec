# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do

      set :ree_install_dir, "/usr/local"
      
      SRC_PACKAGES[:ree] = {
        :url => "http://rubyforge.org/frs/download.php/68719/ruby-enterprise-1.8.7-2010.01.tar.gz",
        :md5sum => "587aaea02c86ddbb87394a340a25e554  ruby-enterprise-1.8.7-2010.01.tar.gz",
        :configure => '',
        :make => '',
        :install => "./installer --auto #{ree_install_dir}"
      }
 
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        gem2.update_system # Install latest rubygems
      end
      
      task :install_deps do
        apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
    end
    
  end
end
