# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  namespace :deprec do 
    namespace :vnstat do
      
      desc <<-EOF
      vnstat description
      EOF
      task :default do
      end
          
      SRC_PACKAGES[:vnstat] = {
        :url => "http://humdi.net/vnstat/vnstat-1.6.tar.gz",
        :md5sum => "ccaffe8e70d47e0cf2f25e52daa25712  vnstat-1.6.tar.gz", 
        :configure => '',
        :post_install => 'vnstat --testkernel && vnstat -u -i eth0'
      }
  
      desc <<-EOF
      Install vnstat. Add interfaces with 'vnstat -u -i ethN' 
      (where N is interface number). 
      
      View stats using the vnstat command line tool.
      EOF
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:vnstat], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:vnstat], src_dir)
      end
  
      # install dependencies for monit
      task :install_deps do
        # apt.install( {:base => %w(flex bison libssl-dev)}, :stable )
      end
    
    end 
    
    
    namespace :vnstat_php do
      
      SRC_PACKAGES[:vnstat_php] = {
        :url => "http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.3.tar.gz",
        :md5sum => "190b37808ae16bd1c1a132434b170437  vnstat_php_frontend-1.3.tar.gz", 
        :configure => '',
        :make => '',
        :install => "test -d /var/www/vnstat_php_frontend-1.3 && rm -fr /var/www/vnstat_php_frontend-1.3; mv #{src_dir}/vnstat_php_frontend-1.3 /var/www && 
          ln -sf /var/www/vnstat_php_frontend-1.3 /var/www/vnstat"
      }
    
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:vnstat_php], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:vnstat_php], src_dir)
      end
    
      # install dependencies for monit
      task :install_deps do
        apt.install( {:base => %w(apache2 php5 php5-gd)}, :stable )
      end
      
      SYSTEM_CONFIG_FILES[:vnstat] = [

        {:template => 'config.php',
         :path => '/var/www/vnstat',
         :mode => 0755,
         :owner => 'root:root'}
         
      ]
      
      task :config_gen do
        SYSTEM_CONFIG_FILES[:vnstat].each do |file|
          deprec2.render_template(:vnstat, file)
        end
      end

      desc "Push monit config files to server"
      task :config do
        deprec2.push_configs(:vnstat, SYSTEM_CONFIG_FILES[:vnstat])
      end
            
    end
    
  end
end
