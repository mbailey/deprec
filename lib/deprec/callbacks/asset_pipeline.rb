# Copyright 2011 Chris Griego
#
# Capistrano::Configuration.instance(:must_exist).load do
# require 'capistrano/recipes/deploy'

def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

_cset :asset_env, "RAILS_GROUPS=assets"
_cset :rails_env, "production"

# rails-3.1 does not use asset timestamps
set :normalize_asset_timestamps, false

after 'deploy:update_code', 'deploy:assets:symlink'
after 'deploy:update_code', 'deploy:assets:precompile'

namespace :deploy do
  namespace :assets do
    desc <<-DESC
      [internal] This task will set up a symlink to the shared directory \
      for the assets directory. Assets are shared across deploys to avoid \
      mid-deploy mismatches between old application html asking for assets \
      and getting a 404 file not found error.
    DESC
    task :symlink, :roles => :web, :except => { :no_release => true } do
      run <<-CMD
        rm -rf #{latest_release}/public/assets &&
        mkdir -p #{latest_release}/public &&
        mkdir -p #{shared_path}/assets &&
        ln -s #{shared_path}/assets #{latest_release}/public/assets
      CMD
    end

    desc <<-DESC
      Run the asset precompilation rake task. You can specify the full path \
      to the rake executable by setting the rake variable. You can also \
      specify additional environment variables to pass to rake via the \
      asset_env variable. The defaults are:

        set :rake,      "rake"
        set :rails_env, "production"
        set :asset_env, "RAILS_GROUPS=assets"
    DESC
    task :precompile, :roles => :web, :except => { :no_release => true } do
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile"
    end

    desc <<-DESC
      Run the asset clean rake task. Use with caution, this will delete \
      all of your compiled assets. You can specify the full path \
      to the rake executable by setting the rake variable. You can also \
      specify additional environment variables to pass to rake via the \
      asset_env variable. The defaults are:

        set :rake,      "rake"
        set :rails_env, "production"
        set :asset_env, "RAILS_GROUPS=assets"
    DESC
    task :clean, :roles => :web, :except => { :no_release => true } do
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:clean"
    end
  end
end
end
