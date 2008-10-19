# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :php do
      
      desc "Install PHP from source"
      task :install do
        set :src_package, {
          :md5sum => '1720f95f26c506338f0dba3a51906bbd  php-5.2.6.tar.gz', 
          :url => "http://www.php.net/distributions/php-5.2.6.tar.gz",
          :configure => %w(
            export CFLAGS=-O2;
            ./configure 
            --prefix=/usr/local/php
            --with-apxs2=/usr/local/apache2/bin/apxs
            --disable-ipv6
            --enable-sockets
            --enable-soap
            --with-pcre-regex
            --with-mysql
            --with-zlib 
            --with-gettext
            --with-sqlite
            --enable-sqlite-utf8
            --with-openssl
            --with-mcrypt
            --with-ncurses
            --with-jpeg-dir=/usr
            --with-gd
            --with-ctype
            --enable-mbstring
            --with-curl==/usr/lib 
            ;
            ).reject{|arg| arg.match '#'}.join(' ')
        }
        install_deps
        deprec2.download_src(src_package, src_dir)
        deprec2.install_from_src(src_package, src_dir)
        deprec2.append_to_file_if_missing('/usr/local/apache2/conf/httpd.conf', 'AddType application/x-httpd-php .php')
      end
      
      # install dependencies for php
      task :install_deps do
        apt.install( {:base => %w(zlib1g-dev zlib1g openssl libssl-dev 
          flex libcurl3 libcurl3-dev libmcrypt-dev libmysqlclient15-dev libncurses5-dev 
          libxml2-dev libjpeg62-dev libpng12-dev)}, :stable )
      end
      
      desc "generate config file for php"
      task :config_gen do
        # not yet implemented
      end
      
      desc "deploy config file for php" 
      task :config, :roles => :web do
        # not yet implemented
      end
      
      task :start, :roles => :web do
        # not applicable
      end
      
      task :stop, :roles => :web do
        # not applicable
      end
      
      task :restart, :roles => :web do
        # not applicable
      end
      
      desc "enable php in webserver"
      task :activate, :roles => :web do
        # not yet implemented
      end  
      
      desc "disable php in webserver"
      task :deactivate, :roles => :web do
        # not yet implemented
      end
      
      task :backup, :roles => :web do
        # not applicable
      end
      
      task :restore, :roles => :web do
        # not applicable
      end
      
    end
  end
end