# Not working
#
# # Copyright 2006-2008 by Mike Bailey. All rights reserved.
# Capistrano::Configuration.instance(:must_exist).load do 
#   namespace :deprec do 
#     namespace :gitosis do
#       
#       # ref: http://scie.nti.st/2007/11/14/hosting-git-repositories-the-easy-and-secure-way
# 
#       set :gitosis_user, 'git'
# 
#       SRC_PACKAGES[:gitosis] = {
#         :url => "git://eagain.net/gitosis.git",
#         :download_method => :git,
#         :configure => '',
#         :make => '',
#         :install => '#{sudo} python setup.py install'
#       }
#       
#       desc "Install gitosis"
#       task :install do
#         install_deps
#         deprec2.download_src(SRC_PACKAGES[:gitosis], src_dir)
#         deprec2.install_from_src(SRC_PACKAGES[:gitosis], src_dir)
#         create_user
#         init
#       end
# 
#       # install dependencies for nginx
#       task :install_deps do
#         apt.install( {:base => %w(python-setuptools)}, :stable )
#       end
# 
#       # Create user for gitosis to run as
#       # This will also be the account you use for ssh access to git
#       task :create_user do
#         run "grep '^#{gitosis_user}:' /etc/passwd || #{sudo} adduser --system --shell /bin/sh --gecos 'git version control' --group --disabled-password --home /home/#{gitosis_user} #{gitosis_user}"
#         sudo "passwd --unlock #{gitosis_user}"
#       end
#       
#       task :init do
#         sudo "sudo -H -u #{git_user} gitosis-init < ~/.ssh/authorized_keys"
#         sudo "chmod 0755 /home/git/repositories/gitosis-admin.git/hooks/post-update" 
#         puts
#         puts "Now check out the gitosis-admin repo, edit configs and push changes back"
#         puts "Your changes with update gitosis as soon as they are checked in."
#         puts
#         puts "git clone git@YOUR_SERVER_HOSTNAME:gitosis-admin.git"
#         puts "cd gitosis-admin"
#         puts ""
#       end
# 
#     end 
#   end
# end