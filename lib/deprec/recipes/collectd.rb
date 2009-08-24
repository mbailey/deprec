# Copyright 2006-2009 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :collectd do
      
      set(:collectd_server) { Capistrano::CLI.ui.ask 'Enter Collectd server hostname' }
            
      # XXX master only
      # Update libdir for libcollectdclient.so.0
      # collectd-nagios is not finding it in /usr/local/lib
      #
      # Copy collection-php to /var/www/collectd

      SRC_PACKAGES[:collectd] = {
        :url => "http://collectd.org/files/collectd-4.7.2.tar.gz",
        :md5sum => "893c7a861b7a4a591188d9468622d89d  collectd-4.7.2.tar.gz",
        :configure => "./configure --prefix=/usr/local;"
      }

      desc "Install collectd"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:collectd], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:collectd], src_dir)
      end

      # install dependencies for sysklogd
      task :install_deps do
        apt.install( {:base => %w(liboping-dev libperl-dev libdbi0-dev libesmtp-dev libganglia1-dev libmemcache-dev libnet1-dev libnotify-dev libopenipmi-dev liboping-dev libpcap-dev libperl-dev librrd2-dev libsensors-dev libstatgrab-dev libvirt-dev)}, :stable )
        apt.install( {:base => %w(rrdtool librrd2-dev librrds-perl libconfig-general-perl libhtml-parser-perl  libregexp-common-perl)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:collectd] = [
        
        {:template => "collectd.conf.erb",
         :path => '/usr/local/etc/collectd.conf',
         :mode => 0640,
         :owner => 'root:root'},
         
      ]
           
      desc "Generate Collectd configs"
      task :config_gen do
        SYSTEM_CONFIG_FILES[:collectd].each do |file|
         deprec2.render_template(:collectd, file)
        end
      end

      desc "Push Chef config files (system & project level) to server"
      task :config, :roles => :all_hosts, :except => {:collectd_master => true} do
        deprec2.push_configs(:collectd, SYSTEM_CONFIG_FILES[:collectd])
        restart
      end

      desc "Start collectd"
      task :start, :roles => :all_hosts, :except => { :collectd_master => true } do
        run "#{sudo} collectd"
      end
      
      desc "Stop collectd"
      task :stop, :roles => :all_hosts, :except => { :collectd_master => true } do
        run "#{sudo} killall collectd; exit 0;"
      end
      
      desc "Restart collectd"
      task :restart, :roles => :all_hosts, :except => { :collectd_master => true } do
        stop
        start
      end

    end 
    
  end
end

# latest rrdtool
# apt-get install intltool
# wget http://oss.oetiker.ch/rrdtool/pub/rrdtool.tar.gz
# tar zxf rrdtool.tar.gz
# cd rrdtool
# ./configure --prefix=/usr/local
# make
# sudo make install
#
# wget http://oss.oetiker.ch/rrdtool/pub/contrib/ruby-rrd-1.1.tar.gz
# tar zxf ruby-rrd-1.1.tar.gz
# cd ruby-rrd-1.1
# ruby extconf.rb
# make
# make install

# Ruby bindings
# RRD.so
