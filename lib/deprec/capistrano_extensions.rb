# Copyright 2006-2008 by Mike Bailey. All rights reserved.
require 'capistrano'
require 'fileutils'

module Deprec2
  
  # Temporarily modify ROLES if HOSTS not set
  # Capistrano's default behaviour is for HOSTS to override ROLES
  def for_roles(roles)
    old_roles = ENV['ROLES']
    ENV['ROLES'] = roles.to_s unless ENV['HOSTS']
    yield
    ENV['ROLES'] = old_roles.to_s unless ENV['HOSTS']
  end
  
  # Temporarily ignore ROLES and HOSTS
  def ignoring_roles_and_hosts
    old_roles = ENV['ROLES']
    old_hosts = ENV['HOSTS']
    ENV['ROLES'] = nil
    ENV['HOSTS'] = nil
    yield
    ENV['ROLES'] = old_roles
    ENV['HOSTS'] = old_hosts
  end
  
  DEPREC_TEMPLATES_BASE = File.join(File.dirname(__FILE__), 'templates')

  # Render template (usually a config file) 
  # 
  # Usually we render it to a file on the local filesystem.
  # This way, we keep a copy of the config file under source control.
  # We can make manual changes if required and push to new hosts.
  #
  # If the options hash contains :path then it's written to that path.
  # If it contains :remote => true, the file will instead be written to remote targets
  # If options[:path] and options[:remote] are missing, it just returns the rendered
  # template as a string (good for debugging).
  #
  #  XXX I would like to get rid of :render_template_to_file
  #  XXX Perhaps pass an option to this function to write to remote
  #
  def render_template(app, options={})
    template = options[:template]
    path = options[:path] || nil
    remote = options[:remote] || false
    mode = options[:mode] || 0755
    owner = options[:owner] || nil
    stage = exists?(:stage) ? fetch(:stage).to_s : ''
    # replace this with a check for the file
    if ! template
      puts "render_template() requires a value for the template!"
      return false 
    end
  
    # If local copies of deprec templates exist they will be used 
    # If you don't specify the location with the local_template_dir option
    # it defaults to config/templates.
    # e.g. config/templates/nginx/nginx.conf.erb
    local_template = File.join(local_template_dir, app.to_s, template)
    if File.exists?(local_template)
      puts
      puts "Using local template (#{local_template})"
      template = ERB.new(IO.read(local_template), nil, '-')
    else
      template = ERB.new(IO.read(File.join(DEPREC_TEMPLATES_BASE, app.to_s, template)), nil, '-')
    end
    rendered_template = template.result(binding)
  
    if remote 
      # render to remote machine
      puts 'You need to specify a path to render the template to!' unless path
      exit unless path
      sudo "test -d #{File.dirname(path)} || #{sudo} mkdir -p #{File.dirname(path)}"
      std.su_put rendered_template, path, '/tmp/', :mode => mode
      sudo "chown #{owner} #{path}" if defined?(owner)
    elsif path 
      # render to local file
      full_path = File.join('config', stage, app.to_s, path)
      path_dir = File.dirname(full_path)
      if File.exists?(full_path)
        if IO.read(full_path) == rendered_template
          puts "[skip] File exists and is identical (#{full_path})."
          return false
        elsif overwrite?(full_path, rendered_template)
          File.delete(full_path)
        else
          puts "[skip] Not overwriting #{full_path}"
          return false
        end
      end
      FileUtils.mkdir_p "#{path_dir}" if ! File.directory?(path_dir)
      # added line above to make windows compatible
      # system "mkdir -p #{path_dir}" if ! File.directory?(path_dir) 
      File.open(full_path, 'w'){|f| f.write rendered_template }
      puts "[done] #{full_path} written"
    else
      # render to string
      return rendered_template
    end
  end
  
  def overwrite?(full_path, rendered_template)
    if defined?(overwrite_all)      
      if overwrite_all == true
        return true
      else
        return false
      end
    end
    
    # XXX add :always and :never later - not sure how to set persistent value from here
    # response = Capistrano::CLI.ui.ask "File exists. Overwrite? ([y]es, [n]o, [a]lways, n[e]ver)" do |q|
    puts
    response = Capistrano::CLI.ui.ask "File exists (#{full_path}). 
    Overwrite? ([y]es, [n]o, [d]iff)" do |q|
      q.default = 'n'
    end
    
    case response
    when 'y'
      return true
    when 'n'
      return false
    when 'd'
      require 'tempfile'
      tf = Tempfile.new("deprec_diff") 
      tf.puts(rendered_template)
      tf.close
      puts
      puts "Running diff -u current_file new_file_if_you_overwrite"
      puts
      system "diff -u #{full_path} #{tf.path} | less"
      puts
      overwrite?(full_path, rendered_template)
    # XXX add :always and :never later - not sure how to set persistent value from here  
    # when 'a'
    #   set :overwrite_all, true
    # when 'e'
    #   set :overwrite_all, false
    end
    
  end

  def render_template_to_file(template_name, destination_file_name, templates_dir = DEPREC_TEMPLATES_BASE)
    template_name += '.conf' if File.extname(template_name) == '' # XXX this to be removed

    file = File.join(templates_dir, template_name)
    buffer = render :template => File.read(file)

    temporary_location = "/tmp/#{template_name}"
    put buffer, temporary_location
    sudo "cp #{temporary_location} #{destination_file_name}"
    delete temporary_location
  end
  
  # Copy configs to server(s). Note there is no :pull task. No changes should 
  # be made to configs on the servers so why would you need to pull them back?
  def push_configs(app, files)   
    app = app.to_s
    stage = exists?(:stage) ? fetch(:stage).to_s : ''
    
    files.each do |file|
      full_local_path = File.join('config', stage, app, file[:path])
      if File.exists?(full_local_path)
        # If the file path is relative we will prepend a path to this projects
        # own config directory for this service.
        if file[:path][0,1] != '/'
          full_remote_path = File.join(deploy_to, app, file[:path]) 
        else
          full_remote_path = file[:path]
        end
        sudo "test -d #{File.dirname(full_remote_path)} || #{sudo} mkdir -p #{File.dirname(full_remote_path)}"
        std.su_put File.read(full_local_path), full_remote_path, '/tmp/', :mode=>file[:mode]
        sudo "chown #{file[:owner]} #{full_remote_path}"
      else
        # Render directly to remote host.
        render_template(app, file.merge(:remote => true))
      end
    end
  end
  
  def teardown_connections
    sessions.keys.each do |server|
         sessions[server].close
         sessions.delete(server)
    end
  end

  def append_to_file_if_missing(filename, value, options={})
    # XXX sort out single quotes in 'value' - they'l break command!
    # XXX if options[:requires_sudo] and :use_sudo then use sudo
    sudo <<-END
    sh -c '
    grep -F "#{value}" #{filename} > /dev/null 2>&1 || 
    echo "#{value}" >> #{filename}
    '
    END
  end

  # create new user account on target system
  def useradd(user, options={})
    options[:shell] ||= '/bin/bash' # new accounts on ubuntu 6.06.1 have been getting /bin/sh
    switches = ''
    switches += " --shell=#{options[:shell]} " if options[:shell]
    switches += ' --create-home ' unless options[:homedir] == false
    switches += " --gid #{options[:group]} " unless options[:group].nil?
    invoke_command "grep '^#{user}:' /etc/passwd || #{sudo} /usr/sbin/useradd #{switches} #{user}", 
    :via => run_method
  end

  # create a new group on target system
  def groupadd(group, options={})
    via = options.delete(:via) || run_method
    # XXX I don't like specifying the path to groupadd - need to sort out paths before long
    invoke_command "grep '#{group}:' /etc/group || #{sudo} /usr/sbin/groupadd #{group}", :via => via
  end

  # add group to the list of groups this user belongs to
  def add_user_to_group(user, group)
    invoke_command "groups #{user} | grep ' #{group} ' || #{sudo} /usr/sbin/usermod -G #{group} -a #{user}",
    :via => run_method
  end

  # create directory if it doesn't already exist
  # set permissions and ownership
  # XXX move mode, path and
  def mkdir(path, options={})
    via = options.delete(:via) || :run
    # XXX need to make sudo commands wrap the whole command (sh -c ?)
    # XXX removed the extra 'sudo' from after the '||' - need something else
    invoke_command "test -d #{path} || #{sudo if via == :sudo} mkdir -p #{path}"
    invoke_command "chmod #{sprintf("%3o",options[:mode]||0755)} #{path}", :via => via if options[:mode]
    invoke_command "chown -R #{options[:owner]} #{path}", :via => via if options[:owner]
    groupadd(options[:group], :via => via) if options[:group]
    invoke_command "chgrp -R #{options[:group]} #{path}", :via => via if options[:group]
  end
  
  def create_src_dir
    mkdir(src_dir, :mode => 0775, :group => group_src, :via => :sudo)
  end
  
  # download source package if we don't already have it
  def download_src(src_package, src_dir)
    set_package_defaults(src_package)
    create_src_dir
    # check if file exists and if we have an MD5 hash or bytecount to compare 
    # against if so, compare and decide if we need to download again
    if defined?(src_package[:md5sum])
      md5_clause = " && echo '#{src_package[:md5sum]}' | md5sum -c - "
    end
    case src_package[:download_method]
      # when getting source with git
      when :git
        # ensure git is installed
        apt.install( {:base => %w(git-core)}, :stable) #TODO fix this to test ubuntu version <hardy might need specific git version for full git submodules support
        package_dir = File.join(src_dir, src_package[:dir])
        run "if [ -d #{package_dir} ]; then cd #{package_dir} && #{sudo} git checkout master && #{sudo} git pull && #{sudo} git submodule init && #{sudo} git submodule update; else #{sudo} git clone #{src_package[:url]} #{package_dir} && cd #{package_dir} && #{sudo} git submodule init && #{sudo} git submodule update ; fi"
      	# Checkout the revision wanted if defined
      	if src_package[:version]
      	  run "cd #{package_dir} && git branch | grep '#{src_package[:version]}$' && #{sudo} git branch -D '#{src_package[:version]}'; exit 0"
      	  run "cd #{package_dir} && #{sudo} git checkout -b #{src_package[:version]} #{src_package[:version]}" 
        end
	
      # when getting source with wget    
      when :http
        # ensure wget is installed
        apt.install( {:base => %w(wget)}, :stable )
        # XXX replace with invoke_command
        run "cd #{src_dir} && test -f #{src_package[:filename]} #{md5_clause} || #{sudo} wget --quiet --timestamping #{src_package[:url]}"
      else
        puts "DOWNLOAD SRC: Download method not recognised. src_package[:download_method]: #{src_package[:download_method]}"
    end
  end

  # unpack src and make it writable by the group
  def unpack_src(src_package, src_dir)
    set_package_defaults(src_package)
    package_dir = File.join(src_dir, src_package[:dir])
    case src_package[:download_method]
      # when unpacking git sources - nothing to do
      when :git
        puts "UNPACK SRC: nothing to do for git installs"
      when :http
        sudo <<-EOF
        bash -c '
        cd #{src_dir};
        test -d #{package_dir}.old && rm -fr #{package_dir}.old;
        test -d #{package_dir} && mv #{package_dir} #{package_dir}.old;
        #{src_package[:unpack]}
        '
        EOF
      else
        puts "UNPACK SRC: Download method not recognised. src_package[:download_method]: #{src_package[:download_method]} "
    end
    sudo <<-EOF
    bash -c '
    cd #{src_dir};
    chgrp -R #{group} #{package_dir};  
    chmod -R g+w #{package_dir};
    '
    EOF
  end

  def set_package_defaults(pkg)
    pkg[:filename] ||= File.basename(pkg[:url])
    pkg[:dir] ||= pkg[:filename].sub(/(\.tgz|\.tar\.gz)/,'')
    pkg[:download_method] ||= :http
    pkg[:unpack] ||= "tar zxf #{pkg[:filename]};"
    pkg[:configure] ||= './configure ;'
    pkg[:make] ||= 'make;'
    pkg[:install] ||= 'make install;'
  end

  # install package from source
  def install_from_src(src_package, src_dir)
    set_package_defaults(src_package)
    package_dir = File.join(src_dir, src_package[:dir])
    unpack_src(src_package, src_dir)
    apt.install( {:base => %w(build-essential)}, :stable )
    sudo <<-SUDO
    sh -c '
    cd #{package_dir};
    #{src_package[:configure]}
    #{src_package[:make]}
    #{src_package[:install]}
    #{src_package[:post_install]}
    '
    SUDO
  end
  
  def read_database_yml
    stage = exists?(:stage) ? fetch(:stage).to_s : ''
    db_config = YAML.load_file(File.join('config', stage, 'database.yml'))
    set :db_user, db_config[rails_env]["username"]
    set :db_password, db_config[rails_env]["password"] 
    set :db_name, db_config[rails_env]["database"]
  end


  ##
  # Run a command and ask for input when input_query is seen.
  # Sends the response back to the server.
  #
  # +input_query+ is a regular expression that defaults to /^Password/.
  #
  # Can be used where +run+ would otherwise be used.
  #
  #  run_with_input 'ssh-keygen ...', /^Are you sure you want to overwrite\?/

  def run_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(:run, shell_command, input_query, response)
  end

  ##
  # Run a command using sudo and ask for input when a regular expression is seen.
  # Sends the response back to the server.
  #
  # See also +run_with_input+
  #
  # +input_query+ is a regular expression

  def sudo_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(:sudo, shell_command, input_query, response)
  end

  def invoke_with_input(shell_command, input_query=/^Password/, response=nil)
    handle_command_with_input(run_method, shell_command, input_query, response)
  end

  ##
  # Run a command using sudo and continuously pipe the results back to the console.
  #
  # Similar to the built-in +stream+, but for privileged users.

  def sudo_stream(command)
    sudo(command) do |ch, stream, out|
      puts out if stream == :out
      if stream == :err
        puts "[err : #{ch[:host]}] #{out}"
        break
      end
    end
  end

  # We don't need this. Put 'USER=root' on the command line instead.
  #
  # XXX Not working in deprec2
  # ##
  # # Run a command using the root account.
  # #
  # # Some linux distros/VPS providers only give you a root login when you install.
  # 
  # def run_as_root(shell_command)
  #   std.connect_as_root do |tempuser|
  #     run shell_command
  #   end
  # end
  # 
  # ##
  # # Run a task using root account.
  # #
  # # Some linux distros/VPS providers only give you a root login when you install.
  # #
  # # tempuser: contains the value replaced by 'root' for the duration of this call
  # 
  # def as_root()
  #   std.connect_as_root do |tempuser|
  #     yield tempuser
  #   end
  # end

  private

  ##
  # Does the actual capturing of the input and streaming of the output.
  #
  # local_run_method: run or sudo
  # shell_command: The command to run
  # input_query: A regular expression matching a request for input: /^Please enter your password/

  def handle_command_with_input(local_run_method, shell_command, input_query, response=nil)
    send(local_run_method, shell_command) do |channel, stream, data|
      logger.info data, channel[:host]
      if data =~ input_query
        if response
          channel.send_data "#{response}\n"
        else 
          response = ::Capistrano::CLI.password_prompt "#{data}"
          channel.send_data "#{response}\n"
        end
      end
    end
  end
  
end

Capistrano.plugin :deprec2, Deprec2
