# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :utils do

        SRC_PACKAGES[:daemonize] = {
          :md5sum => "62aef13cf2dbc305b8c2c033a26cc18d  bmc-daemonize-release-1.6-0-gf9d8e03.tar.gz",
          :url => "http://github.com/bmc/daemonize/tarball/release-1.6",
          :dir => 'bmc-daemonize-f9d8e03'
        }

        namespace :daemonize do

          desc "Install daemonize"
          task :install do
            deprec2.download_src(SRC_PACKAGES[:daemonize], src_dir)
            deprec2.install_from_src(SRC_PACKAGES[:daemonize], src_dir)
          end

        end

        desc "Install some useful network utils"
        task :net do
          apps = %w(lynx nmap netcat telnet dnsutils rsync curl wget)
          apt.install( {:base => apps}, :stable )
        end

        desc "Install some useful mail utils"
        task :mail do
          apps = %w(mailutils mutt)
          apt.install( {:base => apps}, :stable )
        end

        desc "Install some useful utils"
        task :other do
          apps = %w(lsof vim tree psmisc screen)
          apt.install( {:base => apps}, :stable )
        end

        desc "Install handy utils"
        task :handy do
          net
          mail
          other
          top.deprec.ddt.install
        end

        task :remove_consolekit do
          run "#{sudo} killall console-kit-daemon; exit 0"
          run "#{sudo} apt-get -y remove consolekit # chews resources"
        end

    end
  end
end

