# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :utils do
              
        SRC_PACKAGES[:daemonize] = {
          :filename => 'daemonize-1.5.2.tar.gz',   
          :md5sum => "c016f1a17f03ec976873d0a283a1a038  daemonize-1.5.2.tar.gz", 
          :dir => 'daemonize-1.5.2',  
          :url => "http://www.clapper.org/software/daemonize/daemonize-1.5.2.tar.gz",
          :unpack => "tar zxf daemonize-1.5.2.tar.gz;",
          :configure => %w(
            ./configure
            ;
            ).reject{|arg| arg.match '#'}.join(' '),
          :make => 'make;',
          :install => 'make install;'
        }
        
        namespace :daemonize do
        
          desc "Install daemonize"
          task :install do
            deprec2.download_src(SRC_PACKAGES[:daemonize], src_dir)
            deprec2.install_from_src(SRC_PACKAGES[:daemonize], src_dir)
          end
          
        end
     
        task :net do
          apps = %w(lynx nmap netcat
                    vim-full)
          apt.install( {:base => apps}, :stable )
        end
        
    end 
  end
end

