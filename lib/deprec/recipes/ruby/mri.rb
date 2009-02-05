# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :mri do
            
      SRC_PACKAGES[:mri] = {
        :md5sum => "5e5b7189674b3a7f69401284f6a7a36d  ruby-1.8.7-p72.tar.gz", 
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz",
        :configure => "./configure --with-readline-dir=/usr/local;"
      }
  
      desc "Install Rubys"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:mri], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:mri], src_dir)
      end
      
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev)}, :stable )
      end

    end
  end
  
  
  namespace :deprec do
    namespace :rubygems do
  
      SRC_PACKAGES[:rubygems] = {
        :md5sum => "a04ee6f6897077c5b75f5fd1e134c5a9  rubygems-1.3.1.tgz", 
        :url => "http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz",
	      :configure => "",
	      :make =>  "",
        :install => 'ruby setup.rb;'
      }
      
      desc "Install Rubygems"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:rubygems], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:rubygems], src_dir)
        # gem2.upgrade #  you may not want to upgrade your gems right now
      end
      
      # install dependencies for rubygems
      task :install_deps do
      end
      
    end
    
  end
end
