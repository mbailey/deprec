# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ar_sendmail do
      
      desc "Install ar_mailer"
      task :install do
        gem2.install 'ar_mailer'
      end

      # install dependencies for nginx
      task :install_deps do
        #pass
      end
      
      PROJECT_CONFIG_FILES[:ar_sendmail] = [
        
        {:template => 'monit.conf.erb',
         :path => "monit.conf", 
         :mode => 0600,
         :owner => 'root:root'},
         
        {:template => 'logrotate.conf.erb',
         :path => "logrotate.conf", 
         :mode => 0644,
         :owner => 'root:root'}
      ]
       
      task :config_gen do
        config_gen_project
      end
      
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:ar_sendmail].each do |file|
          deprec2.render_template(:ar_sendmail, file)
        end
      end
      
      task :config, :roles => :app do
        config_project
      end
      
      task :config_project, :roles => :app do
        deprec2.push_configs(:ar_sendmail, PROJECT_CONFIG_FILES[:ar_sendmail])
        symlink_monit_config
        symlink_logrotate_config
      end
      
      task :symlink_monit_config, :roles => :app do
        deprec2.mkdir(monit_confd_dir, :via => :sudo)
        sudo "ln -sf #{deploy_to}/ar_sendmail/monit.conf #{monit_confd_dir}/ar_sendmail_#{application}.conf"
      end
      
      task :unlink_monit_config, :roles => :app do
        link = "#{monit_confd_dir}/ar_sendmail_#{application}.conf"
        sudo "test -L #{link} && unlink #{link}"
      end
      
      task :symlink_logrotate_config, :roles => :app do
        sudo "ln -sf #{deploy_to}/ar_sendmail/logrotate.conf /etc/logrotate.d/ar_sendmail-#{application}"
      end
    
    end
  end
end