# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :ree do

      set :ree_version, "ruby-enterprise-1.8.6-20081217"
      set :ree_install_dir, "/opt/#{ree_version}"

      SRC_PACKAGES[:ree] = {
        :filename => "#{ree_version}.tar.gz",   
        :md5sum => "8d04b48e33a485280b86d6cdb156eebe  #{ree_version}.tar.gz", 
        :dir => ree_version,  
        :url => "http://github.com/isaac/rubyenterpriseedition/raw/release/#{ree_version}.tar.gz",
        :unpack => "tar xzvf #{ree_version}.tar.gz;",
        :configure => '',
        :make => '',
        :install => "./installer --auto #{ree_install_dir}"
      }
  
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
      end
      
      task :install_deps do
        apt.install({:base => %w(zlib1g-dev libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end

    end
  end
  
end