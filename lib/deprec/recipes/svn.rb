# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :svn do
  
      desc "Install Subversion"
      task :install do
        install_deps
      end
  
  end
end
