# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do
      
      set :ree_version, 'ruby-enterprise-1.8.6-20090113'
      set :ree_install_dir, "/opt/#{ree_version}"
      set :ree_short_path, '/opt/ruby-enterprise'
      
      SRC_PACKAGES[:ree] = {
        :md5sum => "e8d796a5bae0ec1029a88ba95c5d901d #{ree_version}.tar.gz",
        :url => "http://rubyforge.org/frs/download.php/50087/#{ree_version}.tar.gz",
        :configure => '',
        :make => '',
        :install => "./installer --auto /opt/#{ree_version}"
      }
 
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        symlink_ree
      end
      
      task :install_deps do
        apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
      task :symlink_ree do
        sudo "ln -sf /opt/#{ree_version} #{ree_short_path}"
        sudo "ln -fs #{ree_short_path}/bin/gem /usr/local/bin/gem"
        sudo "ln -fs #{ree_short_path}/bin/irb /usr/local/bin/irb"
        sudo "ln -fs #{ree_short_path}/bin/rake /usr/local/bin/rake"
        sudo "ln -fs #{ree_short_path}/bin/rails /usr/local/bin/rails"
        sudo "ln -fs #{ree_short_path}/bin/ruby /usr/local/bin/ruby"
      end
      
    end
    
  end
end