# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :mri do
            
      SRC_PACKAGES[:mri_1_8_7] = {
        :md5sum => "50a49edb787211598d08e756e733e42e  ruby-1.8.7-p330.tar.gz",
        :url => "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p330.tar.gz",
        :deps => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev),
        :configure => "./configure --with-readline-dir=/usr/local;"
      }

      SRC_PACKAGES[:mri_1_9_2] = {
        :md5sum => "6e17b200b907244478582b7d06cd512e  ruby-1.9.2-p136.tar.gz", 
        :url => "http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p136.tar.gz",
        :deps => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev),
        :configure => "./configure --with-readline-dir=/usr/local;"
      }

      src_package_options = SRC_PACKAGES.keys.select{|k| k.to_s.match /^mri_/ }
      set(:mri_src_package) { Capistrano::CLI.ui.choose *src_package_options }

      desc "Install Ruby"
      task :install do
        deprec2.download_src(SRC_PACKAGES[mri_src_package])
        deprec2.install_from_src(SRC_PACKAGES[mri_src_package])
      end
      
    end
  end
  
end
