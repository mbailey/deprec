# Copyright 2006-2011 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do

      SRC_PACKAGES[:ree_lucid] = {
        :md5sum => "ec29e25e93ac642212790b0ca22e09f9  ruby-enterprise_1.8.7-2011.03_amd64_ubuntu10.04.deb",
        :url => "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise_1.8.7-2011.03_amd64_ubuntu10.04.deb",
        :download_method => :deb
      }

      SRC_PACKAGES[:ree_lucid32] = {
        :md5sum => "bf31bd7cba14ac76b49c3394114b2d31  ruby-enterprise_1.8.7-2011.03_i386_ubuntu10.04.deb",
        :url => "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise_1.8.7-2011.03_i386_ubuntu10.04.deb",
        :download_method => :deb
      }

      SRC_PACKAGES[:ree_src] = {
        :md5sum => "038604ce25349e54363c5df9cd535ec8  ruby-enterprise-1.8.7-2011.03.tar.gz",
        :url => "http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2011.03.tar.gz",
        :deps => %w(zlib1g-dev libssl-dev libreadline5-dev),
        :configure => '',
        :make => '',
        :install => "#{src_dir}/ruby-enterprise-1.8.7-2011.03/installer --auto /usr --dont-install-useful-gems --no-dev-docs"
      }

      src_package_options = SRC_PACKAGES.keys.select{|k| k.to_s.match /^ree_/ }
      set(:ree_src_package) { Capistrano::CLI.ui.choose *src_package_options }

      desc "Install Ruby Enterprise Edition"
      task :install do
        deprec2.download_src(SRC_PACKAGES[ree_src_package])
        deprec2.install_from_src(SRC_PACKAGES[ree_src_package])
      end

    end      
  end
end
