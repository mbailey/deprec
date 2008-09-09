# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  # ref: http://www.howtoforge.com/local_debian_ubuntu_mirror
  namespace :deprec do 

    set :apt_mirror_hostname, 'archive.ubuntu.com'
    set :apt_releases_to_mirror, %w(gutsy)

    namespace :apt_normal do # XXX Find a better name
                             # :apt was clashing with the vmbuilder plugin

      SYSTEM_CONFIG_FILES[:apt] = [

        {:template => 'sources.list',
          :path => '/etc/apt/sources.list',
          :mode => 0755,
          :owner => 'root:root'}
      ]
      
      desc <<-DESC
      Generate apt config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        SYSTEM_CONFIG_FILES[:apt].each do |file|
          deprec2.render_template(:apt, file)
        end
      end

      desc "Push apt_mirror config files to server"
      task :config do
        deprec2.push_configs(:apt, SYSTEM_CONFIG_FILES[:apt])
      end
      
    end
    
    namespace :apt_mirror do
      
      desc "Install apt-mirror"
      task :install, :roles => :apt_mirror do
        install_deps
        SYSTEM_CONFIG_FILES[:apt_mirror].each do |file|
          deprec2.render_template(:apt_mirror, file.merge(:remote => true))
        end
        activate
      end

      # install dependencies for apt_mirror
      task :install_deps do
        apt.install( {:base => %w(apt-mirror apache2 cron)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:apt_mirror] = [

        {:template => 'mirror.list',
          :path => '/etc/apt/mirror.list',
          :mode => 0755,
          :owner => 'root:root'},
        
        {:template => 'apt-mirror-cron',
          :path => '/etc/cron.d/apt-mirror',
          :mode => 0755,
          :owner => 'root:root'}
      ]

      desc <<-DESC
      Generate apt_mirror config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        SYSTEM_CONFIG_FILES[:apt_mirror].each do |file|
          deprec2.render_template(:apt_mirror, file)
        end
      end

      desc "Push apt_mirror config files to server"
      task :config, :roles => :apt_mirror do
        deprec2.push_configs(:apt_mirror, SYSTEM_CONFIG_FILES[:apt_mirror])
      end

      # Create mirror for the first time
      # 
      # su - apt-mirror -c apt-mirror
      
      # Add cron job to update
      
      # Symlink for apache
      # ln -s /var/spool/apt-mirror/mirror/de.archive.ubuntu.com/ubuntu /var/www/ubuntu

      # Update sources.list on all hosts:
      # deb http://192.168.0.100/ubuntu/ gutsy main restricted universe
      
    end 
  end
end