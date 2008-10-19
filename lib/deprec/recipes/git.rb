# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :git do

      set :git_user, 'git'
      set :git_group, 'git'
      set :git_port, '9418'
      set :git_keys_file, '/home/git/.ssh/authorized_keys'
      set :git_root, '/var/git'

      SRC_PACKAGES[:git] = {
        :url => "http://kernel.org/pub/software/scm/git/git-1.6.0.1.tar.gz",
        :md5sum => "7096bac44acbb73f916d3089aa3fdee6  git-1.6.0.1.tar.gz"
      }

      desc "Install git"
      task :install do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:git], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:git], src_dir)
        # create_git_root
        # create_git_user
      end

      # install dependencies for nginx
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev gettext)}, :stable )
      end
      
      # "Start git server in local directory"
      task :serve do
        cmd = "git-daemon --verbose --port=#{git_port} --base-path=#{Dir.pwd} --base-path-relaxed"
        puts cmd
        `#{cmd}`
      end
      
      desc "Create git repos for current dir"
      task :init do
        `git init`
        create_gitignore
        create_files_in_empty_dirs
        `git add . && git commit -m 'initial import'`
      end
      
      task :create_gitignore do
        system("echo '.DS_Store' >> .gitignore") # files sometimes created by OSX 
        system("echo 'log/*' >> .gitignore") if File.directory?('log')
        system("echo 'tmp/**/*' >> .gitignore") if File.directory?('tmp')
      end
      
      task :create_files_in_empty_dirs do
        %w(log tmp).each { |dir| 
          system("touch #{dir}/.gitignore") if File.directory?(dir)
        }
      end
      
      desc "Create remote origin for current dir"
      task :create_remote_origin do
        File.directory?('.git') || init
         
        # Push to remote git repo
        hostname = capture "echo $CAPISTRANO:HOST$"
        system "git remote add origin git@#{hostname.chomp}:#{application}"
        system "git push origin master:refs/heads/master"
        
        puts 
        puts "New remote Git repo: #{git_user}@#{hostname.chomp}:#{application}"
        puts    
        
        # File.open('.git/config', 'w') do |c|
        #   c.write 'Add the following to .git/config'
        #   c.write '[branch "master"]'
        #   c.write ' remote = origin'
        #   c.write ' merge = refs/heads/master'
        # end
          
      end

      # Create root dir for git repositories
      task :create_git_root do
        deprec2.mkdir(git_root, :mode => 02775, :owner => git_user, :group => git_group, :via => :sudo)
        sudo "chmod -R g+w #{git_root}"
      end
      
      # regenerate git authorized keys file from users file in same dir
      task :regenerate_authorized_keys do
        sudo "echo '' > #{git_keys_file}"
        sudo "for file in `ls #{git_keys_file}-*`; do cat $file >> #{git_keys_file}; echo \"\n\" >> #{git_keys_file} ; done"
        sudo "chown #{git_user}.#{git_group} #{git_keys_file}"
        sudo "chmod 0600 #{git_keys_file}" 
      end


    end 
  end
end
