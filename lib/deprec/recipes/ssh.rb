# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ssh do

      set :ssh_permit_root_login, 'no'
      set :ssh_use_pam, 'no'
      set :ssh_use_dns, 'no'
      
      SYSTEM_CONFIG_FILES[:ssh] = [
        
        {:template => "sshd_config.erb",
         :path => '/etc/ssh/sshd_config',
         :mode => 0644,
         :owner => 'root:root'},
         
        {:template => "ssh_config.erb",
         :path => '/etc/ssh/ssh_config',
         :mode => 0644,
         :owner => 'root:root'}
      ]
      
      task :config_gen do        
        SYSTEM_CONFIG_FILES[:ssh].each do |file|
          deprec2.render_template(:ssh, file)
        end
        auth_keys_dir = 'config/ssh/authorized_keys'
        if ! File.directory?(auth_keys_dir)
          puts "Creating #{auth_keys_dir}"
          Dir.mkdir(auth_keys_dir)
        end
      end
      
      desc "Push ssh config files to server"
      task :config do
        deprec2.push_configs(:ssh, SYSTEM_CONFIG_FILES[:ssh])
        restart
      end

      desc "Start ssh"
      task :start do
        send(run_method, "/etc/init.d/ssh reload")
      end
    
      desc "Stop ssh"
      task :stop do
        send(run_method, "/etc/init.d/ssh reload")
      end
    
      desc "Restart ssh"
      task :restart do
        send(run_method, "/etc/init.d/ssh restart")
      end
    
      desc "Reload ssh"
      task :reload do
        send(run_method, "/etc/init.d/ssh reload")
      end
      
      desc "Sets up authorized_keys file on remote server"
      task :setup_keys do
        default(:target_user) { 
          Capistrano::CLI.ui.ask "Setup keys for which user?" do |q|
            q.default = current_user
          end
        }
        
        # If we have an authorized keys file for this user
        # then copy that out
        if File.exists?("config/ssh/authorized_keys/#{target_user}") 
          keys = File.read("config/ssh/authorized_keys/#{target_user}")
        elsif target_user == current_user
          # If the user has specified a key Capistrano should use
          if ssh_options[:keys]
            keys = ssh_options[:keys].collect{|key| File.read("#{key}.pub")}.join("\n")
          # Try to find the current users public key
          elsif key_files = %w[id_rsa id_dsa identity].collect { |f| "#{ENV['HOME']}/.ssh/#{f}.pub" if File.exists?("#{ENV['HOME']}/.ssh/#{f}.pub") }.compact
            keys = key_files.collect{|key| File.read(key)}.join("\n")
          else
            puts <<-ERROR

            You need to define the name of your SSH key(s)
            e.g. ssh_options[:keys] = %w(/Users/your_username/.ssh/id_rsa)

            You can put this in your .caprc file in your home directory.

            ERROR
            exit
          end
        else
          puts <<-ERROR
          
          Could not find ssh public key(s) for user #{target_user}
         
          Please create file containing ssh public keys in:
          
          config/ssh/authorized_keys/#{target_user}
            
          ERROR
          exit
        end
        
        # copy keys to remote server
        deprec2.mkdir "/home/#{target_user}/.ssh", :mode => 0700, :owner => "#{target_user}.users", :via => :sudo
        std.su_put keys, "/home/#{target_user}/.ssh/authorized_keys", '/tmp/', :mode => 0600
        sudo "chown #{target_user}.users /home/#{target_user}/.ssh/authorized_keys"
      end

    end
  end
end
