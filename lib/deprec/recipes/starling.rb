# Deprec script to install the Starling Messaging Server
# This uses the forked copy located at http://github.com/starling/starling instead of the original gem
# The start/stop/restart tasks are based on code used in the 'starling.ubuntu' script which is contained in the Starling repository.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :starling do
      set :starling_port, 15151
      set :starling_address, "127.0.0.1"
      set :starling_user, "starling"
      set :starling_group, "starling"
      set :starling_spool_dir, "/var/spool/starling"
      set :starling_run_dir, "/var/run/starling"
      set :starling_log_dir, "/var/log/starling"
      set :starling_runtime_options, "-h #{starling_address} -p #{starling_port} -d -q #{starling_spool_dir} -P #{starling_spool_dir}/starling.pid -L #{starling_log_dir}/starling.log"
      
      # Installation
      desc "Installs the Starling gem"
      task :install, :roles => :app do
        sudo("gem install eventmachine --no-rdoc --no-ri")
        sudo("gem install starling-starling --source http://gems.github.com -v 0.9.9 --no-rdoc --no-ri")

        deprec2.mkdir(starling_spool_dir, :via => :sudo)
        deprec2.mkdir(starling_run_dir, :via => :sudo)
        deprec2.mkdir(starling_log_dir, :via => :sudo)

        create_starling_user_and_group
        set_perms_for_starling_dirs
        symlink_starling_for_rubyee if ruby_vm_type == :ree

        SYSTEM_CONFIG_FILES[:starling].each do |file|
          deprec2.render_template(:starling, file.merge(:remote=>true))
        end

        activate
      end

      # Control

      desc "Starts the Starling server"
      task :start, :roles => :app do
        send(run_method, "start-stop-daemon -c #{starling_user}:#{starling_group} --start --quiet --pidfile #{starling_run_dir}/starling.pid --exec /usr/local/bin/starling -- #{starling_runtime_options}")
      end
      
      desc "Stops the Starling server"
      task :stop, :roles => :app do
        send(run_method, "start-stop-daemon -c #{starling_user}:#{starling_group} --stop --quiet --pidfile #{starling_run_dir}/starling.pid --exec /usr/local/bin/starling -- #{starling_runtime_options}")
      end

      desc "Restarts the Starling server"
      task :restart, :roles => :app do
        send(run_method, "start-stop-daemon -c #{starling_user}:#{starling_group} --stop --quiet --pidfile #{starling_run_dir}/starling.pid --exec /usr/local/bin/starling -- #{starling_runtime_options}")
        sleep(2)
        send(run_method, "start-stop-daemon -c #{starling_user}:#{starling_group} --start --quiet --pidfile #{starling_run_dir}/starling.pid --exec /usr/local/bin/starling -- #{starling_runtime_options}")
      end

      task :activate, :roles => :app do
        send(run_method, "update-rc.d starling defaults")
      end

      task :deactivate, :roles => :app do
        send(run_method, "update-rc.d -f starling remove")
      end

      # Generating Configuration Files
      desc "Generate configuration file(s) for Starling from template(s)"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:starling].each do |file|
          deprec2.render_template(:starling, file)
        end  
      end

      desc 'Deploy configuration files(s) for Starling'
      task :config, :roles => :app do
        deprec2.push_configs(:starling, SYSTEM_CONFIG_FILES[:starling])
      end

      # User/Group creation & permission assignment
      # These were based off the tasks used in the mongrel recipe - as this was probably
      # the nicest way to ensure these tasks were doing the right thing.
      desc "create user and group for starling to run as"
      task :create_starling_user_and_group, :roles => :app do
        deprec2.groupadd(starling_group) 
        deprec2.useradd(starling_user, :group => starling_group, :homedir => false)
        # Set the primary group for the starling user (in case user already existed
        # when previous command was run)
        sudo "usermod --gid #{starling_group} #{starling_user}"
      end
      
      desc "set group ownership and permissions on dirs starling needs to write to"
      task :set_perms_for_starling_dirs, :roles => :app do
        sudo "chgrp -R #{starling_group} #{starling_spool_dir} #{starling_run_dir} #{starling_log_dir}"
        sudo "chmod -R g+w #{starling_spool_dir} #{starling_run_dir} #{starling_log_dir}" 
      end      

      task :symlink_starling_for_rubyee, :roles => :app do
        # This ensures we symlink from the REE common directory, NOT the
        # actual REE install directory (so when we change the REE version,
        # we don't have to fuddle around again).
        sudo "ln -s #{ree_short_path}/bin/starling /usr/local/bin/starling"
      end

      # Configure
      SYSTEM_CONFIG_FILES[:starling] = [
        {:template => 'starling-init-script.erb',
         :path => '/etc/init.d/starling',
         :mode => 0755,
         :owner => 'root:root'},
         
         {:template => 'monit.conf.erb',
          :path => "/etc/monit.d/monit_starling.conf", 
          :mode => 0600,
          :owner => 'root:root'}
      ]
    end
  end
end