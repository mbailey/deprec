# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :users do
      
      # desc "Create user account"
      # task :add do
      #   target_user = Capistrano::CLI.ui.ask "Enter userid for new user" do |q|
      #     q.default = user
      #   end
      #   deprec2.useradd(target_user, :shell => '/bin/bash')
      #   puts "Setting password for new account"
      #   deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/)
      # end
      
      desc "Create account"
      task :add do
        target_user = Capistrano::CLI.ui.ask "Enter userid for new user" do |q|
          q.default = user
        end 
        make_admin = Capistrano::CLI.ui.ask "Should this be an admin account?" do |q|
          q.default = 'no'
        end
        copy_keys = false
        if File.readable?("config/ssh/authorized_keys/#{target_user}")
          copy_keys = Capistrano::CLI.ui.ask "I've found an authorized_keys file for #{target_user}. Should I copy it out?" do |q|
            q.default = 'yes'
          end
        end
        
        new_password = Capistrano::CLI.ui.ask("Enter new password for #{target_user}") { |q| q.echo = false }
        
        deprec2.useradd(target_user, :shell => '/bin/bash')

        deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/, new_password)
        
        if make_admin.grep(/y/i)
          deprec2.groupadd('admin')
          deprec2.add_user_to_group(target_user, 'admin')
          deprec2.append_to_file_if_missing('/etc/sudoers', '%admin ALL=(ALL) ALL')
        end
        
        if copy_keys && copy_keys.grep(/y/i)
          set :target_user, target_user
          top.deprec.ssh.setup_keys
        end
        
      end
      
      desc "Create account"
      task :add_admin do
        puts 'deprecated! use deprec:users:add'
        add
      end
  
      desc "Change user password"
      task :passwd do
        target_user = Capistrano::CLI.ui.ask "Enter user to change password for" do |q|
          q.default = user if user.is_a?(String)
        end
        new_password = Capistrano::CLI.ui.ask("Enter new password for #{target_user}") { |q| q.echo = false }
  
        deprec2.invoke_with_input("passwd #{target_user}", /UNIX password/, new_password) 
      end
      
      desc "Add user to group"
      task :add_user_to_group do
        target_user = Capistrano::CLI.ui.ask "Which user?" do |q|
          q.default = user if user.is_a?(String)
        end
        target_group = Capistrano::CLI.ui.ask "Add to which group?" do |q|
          q.default = 'deploy'
        end
        deprec2.add_user_to_group(target_user, target_group)
      end

      # desc "Create group"
      # task :add_group do
      #   target_group = Capistrano::CLI.ui.ask "Enter name for new group" 
      #   deprec2.groupadd(target_group)
      # end
      # 
      # desc "Add user to group"
      # task :add_user_to_group do
      #   # XXX not yet implemented
      # end

    end
  end
end