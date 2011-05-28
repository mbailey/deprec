# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :git do

      # Ubuntu lucid has a new enough version of git
      desc "Install git"
      task :install do
        apt.install( {:base => %w(git-core)}, :stable )
      end

    end 
  end
end
