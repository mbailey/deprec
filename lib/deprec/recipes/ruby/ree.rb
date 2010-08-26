# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do

      set :ree_version, 'ruby-enterprise-1.8.7-2010.02'
      set :ree_install_dir, "/usr/local"
      
      SRC_PACKAGES[:ree] = {
        :md5sum => "4df7b09c01adfd711b0ab76837611542 #{ree_version}.tar.gz",
        :url => "http://rubyforge.org/frs/download.php/71096/#{ree_version}.tar.gz",
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
