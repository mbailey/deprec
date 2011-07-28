require 'deprec-core'
Capistrano::Configuration.instance(:must_exist).load do 

  namespace :deprec do
    namespace :mri do
            
      SRC_PACKAGES['ruby-1.8.7-p352'] = {
        :md5sum => "0c33f663a10a540ea65677bb755e57a7  ruby-1.8.7-p352.tar.gz",
        :url => "http://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p352.tar.gz",
        :deps => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev),
        :configure => "./configure --with-readline-dir=/usr/local;"
      }

      SRC_PACKAGES['ruby-1.9.2-p290'] = {
        :md5sum => "604da71839a6ae02b5b5b5e1b792d5eb  ruby-1.9.2-p290.tar.gz", 
        :url => "http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz",
        :deps => %w(zlib1g-dev libssl-dev libncurses5-dev libreadline5-dev),
        :configure => "./configure",
        :post_install => 'sudo gem update --system'
      }

      src_package_options = SRC_PACKAGES.keys.select{|k| k.match /^ruby-\d\.\d\.\d/ }
      set(:mri_src_package) { 
        puts "Select mri_src_package from list:"
        Capistrano::CLI.ui.choose do |menu|
          menu.choices(*src_package_options)
        end
      }

      desc "Install Ruby"
      task :install do
        deprec2.download_src(SRC_PACKAGES[mri_src_package])
        deprec2.install_from_src(SRC_PACKAGES[mri_src_package])
      end
      
    end
  end
  
end
