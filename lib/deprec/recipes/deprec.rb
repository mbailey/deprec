# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  # Set the value if not already set
  # This method is accessible to all recipe files
  def self.default(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end
  
  # Deprec checks here for local versions of config templates before it's own
  set :local_template_dir, File.join('config','templates')
  
  # The following two Constants contain details of the configuration 
  # files used by each service. They're used when generating config
  # files from templates and when configs files are pushed out to servers.
  #
  # They are populated by the recipe file for each service
  #
  SYSTEM_CONFIG_FILES  = {} # e.g. httpd.conf
  PROJECT_CONFIG_FILES = {} # e.g. projectname-httpd-vhost.conf
  
  # For each service, the details of the file to download and options
  # to configure, build and install the service
  SRC_PACKAGES = {} unless defined?(SRC_PACKAGES)
  
  # Server options
  CHOICES_RUBY_VM   = [:mri, :ree]
  CHOICES_WEBSERVER = [:nginx, :apache, :none]
  CHOICES_APPSERVER = [:mongrel, :webrick, :passenger, :none]
  CHOICES_DATABASE  = [:mysql, :postgresql, :sqlite, :none]
  
  # Service defaults
  #
  # The defaults below are legacy values to support older deployments.
  # Newly generated deploy.rb files have use apache, passenger and ree 
  default :ruby_vm_type,    :mri
  default :web_server_type, :nginx
  default :app_server_type, :mongrel
  default :db_server_type,  :mysql
  #
  # default(:web_server_type) do
  #   Capistrano::CLI.ui.choose do |menu| 
  #     CHOICES_WEBSERVER.each {|c| menu.choice(c)}
  #     menu.header = "select webserver type"
  #   end
  # end
  # 
  # default(:app_server_type) do
  #   Capistrano::CLI.ui.choose do |menu| 
  #     CHOICES_APPSERVER.each {|c| menu.choice(c)}
  #     menu.header = "select application server type"
  #   end
  # end
  # 
  # default(:db_server_type) do
  #   Capistrano::CLI.ui.choose do |menu| 
  #     CHOICES_DATABASE.each {|c| menu.choice(c)}
  #     menu.header = "select database server type"
  #   end
  # end

  default(:application) do
    Capistrano::CLI.ui.ask "Enter name of project(no spaces)" do |q|
      q.validate = /^[0-9a-z_]*$/
    end
  end 

  default(:domain) do
    Capistrano::CLI.ui.ask "Enter domain name for project" do |q|
      q.validate = /^[0-9a-z_\.]*$/
    end
  end

  default(:repository) do
    Capistrano::CLI.ui.ask "Enter repository URL for project" do |q|
      # q.validate = //
    end
  end

  # some tasks run commands requiring special user privileges on remote servers
  # these tasks will run the commands with:
  #   :invoke_command "command", :via => run_method
  # override this value if sudo is not an option
  # in that case, your use will need the correct privileges
  default :run_method, :sudo 

  default(:backup_dir) { '/var/backups'}  

  # XXX rails deploy stuff
  set :apps_root,     File.join( %w(/ opt apps) )          # parent dir for apps
  default(:deploy_to)    { File.join(apps_root, application) } # dir for current app
  default(:current_path) { File.join(deploy_to, "current") }
  default(:shared_path)  { File.join(deploy_to, "shared") }

  # XXX more rails deploy stuff?

  default :user, ENV['USER']         # user who is deploying
  default :group, 'deploy'           # deployment group
  default(:group_src) { group }      # group ownership for src dir
  default :src_dir, '/usr/local/src' # 3rd party src on servers lives here
  default(:web_server_aliases) { domain.match(/^www/) ? [] : ["www.#{domain}"] }    

  # XXX for some reason this is causing "before deprec:rails:install" to be executed twice
  on :load, 'deprec:connect_canonical_tasks' 

  namespace :deprec do
    
    task :connect_canonical_tasks do      
      # link application specific recipes into canonical task names
      # e.g. deprec:web:restart => deprec:nginx:restart 
      
      
      namespaces_to_connect = { :web => :web_server_type,
                                :app => :app_server_type,
                                :db  => :db_server_type,
                                :ruby => :ruby_vm_type
                              }
      metaclass = class << self; self; end # XXX unnecessary?
      namespaces_to_connect.each do |server, choice|
        server_type = send(choice).to_sym
        if server_type != :none
          metaclass.send(:define_method, server) { namespaces[server] } # XXX unnecessary?
          namespaces[server] = deprec.send(server_type)          
        end
      end
    end

    task :dump do
      require 'yaml'
      y variables
    end
    
    task :setup_src_dir do
      deprec2.groupadd(group_src)
      deprec2.add_user_to_group(user, group_src)
      deprec2.create_src_dir
    end
    
    # Download all packages used by deprec to your local host.
    # You can then push them to /usr/local/src on target hosts
    # to save time and bandwidth rather than repeatedly downloading
    # from the distribution sites.
    task :update_src do
      SRC_PACKAGES.each{|key, src_package| 
        current_dir = Dir.pwd
        system "cd src/ && test -f #{src_package[:filename]} || wget --quiet --timestamping #{src_package[:url]}"
        system "cd #{current_dir}"
      }
    end
    
    # todo
    #
    # Copy files from src/ to /usr/local/src/ on remote hosts
    task :push_src do
      SRC_PACKAGES.each do |key, src_package| 
        deprec2.set_package_defaults(src_package)
        file = File.join('src', src_package[:filename])
        if File.exists?(file)
          std.su_put(File.read(file), "#{src_dir}/#{src_package[:filename]}", '/tmp/')
        end
      end
    end
    
    task :list_src do
      # XXX ugly line - look away
      max_key_size = SRC_PACKAGES.keys.max{|a,b| a.to_s.size <=> b.to_s.size}.to_s.size
      SRC_PACKAGES.each{|key, src_package| 
        deprec2.set_package_defaults(src_package)
        puts "#{key}#{' '*(max_key_size+1-key.to_s.size)}: #{src_package[:url]}"
      }
    end
    
    task :find_src do
      # XXX ugly line - look away
      max_key_size = SRC_PACKAGES.keys.max{|a,b| a.to_s.size <=> b.to_s.size}.to_s.size
      SRC_PACKAGES.each{|key, src_package| 
        deprec2.set_package_defaults(src_package)
        puts "#{key}#{' '*(max_key_size+1-key.to_s.size)}: #{src_package[:url]}"
        puts `find . -name #{src_package[:filename]}`
        puts
      }
    end
    
    task :recover_src do
      # XXX ugly line - look away
      max_key_size = SRC_PACKAGES.keys.max{|a,b| a.to_s.size <=> b.to_s.size}.to_s.size
      SRC_PACKAGES.each{|key, src_package| 
        puts "#{key}#{' '*(max_key_size+1-key.to_s.size)}: #{src_package[:url]}"
        file = `find . -name #{src_package[:filename]}`.split[0]
        `cp #{file} src/` if file
        puts
      }
    end
     
  end
  
end
