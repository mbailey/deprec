# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :users do

      set(:users_target_user) { Capistrano::CLI.ui.ask "Enter userid for new user" do |q| q.default = current_user; end }
      set(:users_target_group) { Capistrano::CLI.ui.ask "Enter group name for new user" do |q| q.default = 'deploy'; end }
      set(:users_make_admin) { Capistrano::CLI.ui.ask "Should this be an admin account?" do |q| q.default = 'no'; end }
      
      desc "Create account"
      task :add do
        [users_target_user, users_target_group, users_make_admin] # get input
       
        while true do
          new_password = Capistrano::CLI.ui.ask("Enter new password for #{users_target_user}") { |q| q.echo = false }
          password_conf = Capistrano::CLI.ui.ask("Re-enter new password for #{users_target_user}") { |q| q.echo = false }
          if new_password != password_conf
            puts "Fail. Passwords do not match.\n\n"
          elsif new_password.chomp == ""
            puts "Fail. Passwords cannot be empty.\n\n"
          else
            break
          end
        end 

        # Grab a list of all users with keys
        if users_target_user == 'all'
          set :users_target_user, Dir.entries('config/ssh/authorized_keys').reject{|f| ['.','..'].include? f}
        end

        Array(users_target_user).each do |user| 
        
          deprec2.useradd(user, :shell => '/bin/bash')
          deprec2.invoke_with_input("passwd #{user}", /UNIX password/, new_password)
        
          if users_make_admin.match(/y/i)
            deprec2.groupadd('admin')
            deprec2.add_user_to_group(user, 'admin')
            deprec2.append_to_file_if_missing('/etc/sudoers', '%admin ALL=(ALL) ALL')
          end
        
          set :target_user, user
          top.deprec.ssh.setup_keys
        end
        
      end
  
      desc "Change user password"
      task :passwd do
        new_password = Capistrano::CLI.ui.ask("Enter new password for #{users_target_user}") { |q| q.echo = false }
  
        deprec2.invoke_with_input("passwd #{users_target_user}", /UNIX password/, new_password) 
      end
      
      desc "Add user to group"
      task :add_user_to_group do
        deprec2.add_user_to_group(users_target_user, users_target_group)
      end

      desc "Create account"
      task :add_admin do
        puts 'deprecated! use deprec:users:add'
        add
      end

    end
  end
end
