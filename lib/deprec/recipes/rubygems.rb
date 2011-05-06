# Copyright by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do

  namespace :deprec do
    namespace :rubygems do

      SRC_PACKAGES[:rubygems] = {
        :md5sum => "b5badb7c5adda38d9866fa21ae46bbcc  rubygems-1.4.2.tgz",
        :url => "http://rubyforge.org/frs/download.php/73882/rubygems-1.4.2.tgz",
        :configure => "",
        :make =>  "",
        :install => 'ruby setup.rb; exit 0;' # rubygems 1.4.2 is a bit broken http://bit.ly/k1IfUa
      }

      desc "Install Rubygems"
      task :install do
        deprec2.download_src(SRC_PACKAGES[:rubygems])
        deprec2.install_from_src(SRC_PACKAGES[:rubygems])
      end

      desc "Upgrade to the latest version of Rubygems"
      task :update_system do
        gem2.update_system
      end

    end
  end

end
