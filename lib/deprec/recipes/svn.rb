# Copyright 2006-2008 by Mike Bailey. All rights reserved.
require 'fileutils'
require 'uri'

# http://svnbook.red-bean.com/en/1.4/svn-book.html#svn.serverconfig.choosing.apache

Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do namespace :svn do
  
  set :scm_group, 'scm'
  
  # Extract svn attributes from :repository URL
  # 
  # Two examples of :repository entries are:
  #
  #   set :repository, 'svn+ssh://scm.deprecated.org/var/svn/deprec/trunk'
  #   set :repository, 'file:///tmp/svn/deprec/trunk'
  #
  # This has only been tested with svn+ssh but file: should work.
  #
  set (:svn_scheme) { URI.parse(repository).scheme }  
  set (:svn_host)   { URI.parse(repository).host }
  set (:repos_path) { URI.parse(repository).path }
  set (:repos_root) { 
    URI.parse(repository).path.sub(/\/(trunk|tags|branches)$/, '') 
  }
  
  # account name to perform actions on (such as granting access to an account)
  # this is a hack to allow us to optionally pass a variable to tasks 
  set (:svn_account) do
    Capistrano::CLI.ui.ask 'account name'
  end
  
  set(:svn_backup_dir) { File.join(backup_dir, 'svn') }
  
  desc "Install Subversion"
  task :install, :roles => :scm do
    install_deps
    # XXX should really check if apache has already been installed
    # XXX can do that when we move to rake
    # deprec2.download_src(src_package, src_dir)
    # deprec2.install_from_src(src_package, src_dir)
  end
  
  desc "install dependencies for Subversion"
  task :install_deps do
    apt.install( {:base => %w(subversion)}, :stable )
    # XXX deprec1 - was building from source to get subversion-1.4.5 onto dapper. Compiled swig bindings for trac
    # apt.install( {:base => %w(build-essential wget libneon25 libneon25-dev swig python-dev libexpat1-dev)}, :stable )
  end
  
  desc "grant a user access to svn repos"
  task :grant_user_access, :roles => :scm do
    # creates account, scm_group and adds account to group
    deprec2.useradd(svn_account)
    deprec2.groupadd(scm_group) 
    deprec2.add_user_to_group(svn_account, scm_group)
  end
  
  desc "Create subversion repository and import project into it"
  task :setup, :roles => :scm do 
    create_repos
    import
  end
  
  desc "Create a subversion repository"
  task :create_repos, :roles => :scm do
    set :svn_account, top.user
    grant_user_access
    deprec2.mkdir(repos_root, :mode => 02775, :group => scm_group, :via => :sudo)
    sudo "svnadmin verify #{repos_root} > /dev/null 2>&1 || sudo svnadmin create #{repos_root}"
    sudo "chmod -R g+w #{repos_root}"
  end
  
  # Adapted from code in Bradley Taylors RailsMachine gem
  desc "Import project into subversion repository."
  task :import, :roles => :scm do 
    new_path = "../#{application}"
    tags = repository.sub("trunk", "tags")
    branches = repository.sub("trunk", "branches")
    puts "Adding branches and tags"
    system "svn mkdir -m 'Adding tags and branches directories' #{tags} #{branches}"
    puts "Importing application."
    system "svn import #{repository} -m 'Import'"
    cwd = Dir.getwd
    puts "Moving application to new directory"
    Dir.chdir '../'
    system "mv #{cwd} #{cwd}.imported"
    puts "Checking out application."
    system "svn co #{repository} #{application}"
    Dir.chdir application
    remove_log_and_tmp
    puts "Your repository is: #{repository}" 
  end
  
  # Lifted from Bradley Taylors RailsMachine gem
  desc "remove and ignore log files and tmp from subversion"
  task :remove_log_and_tmp, :roles => :scm  do
    puts "removing log directory contents from svn"
    system "svn remove log/*"
    puts "ignoring log directory"
    system "svn propset svn:ignore '*.log' log/"
    system "svn update log/"
    puts "removing contents of tmp sub-directorys from svn"
    system "svn remove tmp/cache/*"
    system "svn remove tmp/pids/*"
    system "svn remove tmp/sessions/*"
    system "svn remove tmp/sockets/*"
    puts "ignoring tmp directory"
    system "svn propset svn:ignore '*' tmp/cache"
    system "svn propset svn:ignore '*' tmp/pids"
    system "svn propset svn:ignore '*' tmp/sessions"
    system "svn propset svn:ignore '*' tmp/sockets"
    system "svn update tmp/"
    puts "committing changes"
    system "svn commit -m 'Removed and ignored log files and tmp'"
  end
  
  # desc "Cache svn name and password on the server. Useful for http-based repositories."
  task :cache_credentials do
    run_with_input "svn list #{repository}"
  end
  
  desc "create backup of trac repository"
  task :backup, :roles => :scm do
    # http://svnbook.red-bean.com/nightly/en/svn.reposadmin.maint.html#svn.reposadmin.maint.backup
    # XXX do we need this? insane!
    # echo "REPOS_BASE=/var/svn" > ~/.svntoolsrc
    DATE=`date +%Y%m%d-%a`
    
    timestamp = Time.now.strftime("%Y%m%d-%a")
    deprec2.mkdir(svn_backup_dir, :owner => :root, :group => :deploy, :mode => 0775, :via => :sudo)
    dest_dir = File.join(svn_backup_dir, "#{application}_#{timestamp}")
    sudo "svnadmin hotcopy #{repos_root} #{dest_dir}"
  end

  task :restore, :roles => :scm do
    # prompt user to select from list of locally stored backups
    # tracd_stop
    # copy out backup
  end
  
  
  # XXX TODO
  # desc "backup repository" 
  # task :svn_backup_respository, :roles => :scm do
  #   puts "read http://svnbook.red-bean.com/nightly/en/svn-book.html#svn.reposadmin.maint.backup"
  # end

  end end
end

# svnserve setup
# I've previously used ssh exclusively I've decided svnserve is a reasonable choice for collaboration on open source projects.
# It's easier to setup than apache/ssl webdav access.
#
# sudo useradd svn
# sudo mkdir -p /var/svn/deprec_svnserve_root
# sudo ln -sf /var/www/apps/deprec/repos /var/svn/deprec_svnserve_root/deprec
# sudo chown -R svn /var/svn/deprec_svnserve_root/deprec

#
# XXX put password file into svn and command to push it
# 
# # run svnserve
# sudo -u svn svnserve --daemon --root /var/svn/deprec_svnserve_root
# 
# # check it out now
# svn co svn://scm.deprecated.org/deprec/trunk deprec
