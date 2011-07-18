require 'deprec-core'
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :deploy do

      desc "Make deploy_to writable by deploy user"
      task :chown, :roles => :app do
        run "#{sudo} chown -R #{user} #{deploy_to}"
      end

      desc "Symlink database.yml"
      task :symlink_database_yml, :roles => :app do
        run "ln -nfs #{shared_path}/system/database.yml #{release_path}/config/database.yml"
      end

      desc "Symlink shared/system/backups into latest_release"
      task :symlink_backups, :roles => :app do
        run "test -d #{shared_path}/system/backups || mkdir #{shared_path}/system/backups"
        run "ln -nfs #{shared_path}/system/backups #{latest_release}/db/backups"
      end
      
    end
  end
end
