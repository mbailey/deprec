# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :ntp do


      # Install      

      desc "Install ntp"
      task :install do
        install_deps
      end

      # install dependencies for nginx
      task :install_deps do
        apt.install( {:base => %w(ntp)}, :stable )
      end


      # Configure

      SYSTEM_CONFIG_FILES[:ntp] = [

        {:template => 'ntp.conf.erb',
          :path => '/etc/ntp.conf',
          :mode => 0755,
          :owner => 'root:root'}
      ]

      desc "Generate ntp config from template."
      task :config_gen do
        SYSTEM_CONFIG_FILES[:ntp].each do |file|
          deprec2.render_template(:ntp, file)
        end
      end

      desc "Push ntp config files to server"
      task :config do
        deprec2.push_configs(:ntp, SYSTEM_CONFIG_FILES[:ntp])
      end

      desc 'Enable ntp start scripts on server.'
      task :activate, :roles => :web do
        send(run_method, "update-rc.d ntp defaults")
      end

      desc 'Disable ntp start scripts on server.'
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f ntp remove")
      end


      # Control

      desc "Start ntp"
      task :start do
        send(run_method, "/etc/init.d/ntp start")
      end

      desc "Stop ntp"
      task :stop do
        send(run_method, "/etc/init.d/ntp stop")
      end

      desc "Restart ntp"
      task :restart do
        send(run_method, "/etc/init.d/ntp restart")
      end

      desc "Reload ntp"
      task :reload do
        puts "use 'restart' instead"
        exit 1
      end

      task :backup, :roles => :web do
        # there's nothing to backup for ntp
      end

      task :restore, :roles => :web do
        # there's nothing to store for ntp
      end

    end 
  end
end


# Some nice nagios checks
#
# Check important hosts have expected DNS
#
# root@sm02:/usr/local/nagios/libexec# ./check_dns --hostname=astro.blocksglobal.com --expected-address=116.240.200.167
# DNS OK: 0.009 seconds response time. astro.blocksglobal.com returns 116.240.200.167|time=0.008744s;;;0.000000
#
#
