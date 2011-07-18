require 'deprec-core'
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
