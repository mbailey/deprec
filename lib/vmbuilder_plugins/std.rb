# =std.rb: Capistrano Standard Methods
# Standard library of procedures and functions that you can use with Capistrano.
# 
# ----
# Copyright (c) 2007 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# = Purpose
# Std is a Capistrano plugin that provides a set of standard methods refactored
# out of several Capistrano task libraries.
#
# Installs within Capistrano as the plugin _std_
#
# = Usage
#
#    require 'vmbuilder_plugins/std'
#
# Prefix all calls to the library with <tt>std.</tt>
module Std

  begin
    # Use the Mmap class if it is available
    # http://moulon.inra.fr/ruby/mmap.html    
    require 'mmap'
    MMAP=true #:nodoc:
  rescue LoadError
    # no MMAP class, use normal reads instead
    MMAP=false #:nodoc:
  end

  # Copies the files specified by +file_pattern+ to +destination+
  #
  # Error checking is minimal - a pattern onto a single file will result in +destination+
  # containing the data from the last file only.
  #
  # Installs via *sudo*,  +options+ are as for *put*.
  def fput(file_pattern, destination, options={})
    logger.info file_pattern
    Dir.glob(file_pattern) do |fname|
      if File.readable?(fname) then
	if MMAP
	  logger.debug "Using Memory Mapped File Upload"
	  fdata=Mmap.new(fname,"r", Mmap::MAP_SHARED, :advice => Mmap::MADV_SEQUENTIAL)
        else
	  fdata=File.open(fname).read
	end
	su_put(fdata, destination, File.join('/tmp',File.basename(fname)), options)
      else
	logger.error "Unable to read file #{fname}"
      end
    end
  end

  # Upload +data+ to +temporary_area+ before installing it in
  # +destination+ using sudo.
  #
  # +options+ are as for *put*
  #
  def su_put(data, destination, temporary_area='/tmp', options={})
    temporary_area = File.join(temporary_area,"#{File.basename(destination)}-$CAPISTRANO:HOST$") 
    put(data, temporary_area, options)
    send run_method, <<-CMD
      sh -c "install -m#{sprintf("%3o",options[:mode]||0755)} #{temporary_area} #{destination} &&
      rm -f #{temporary_area}"
    CMD
  end
  
  # Copies the +file_pattern+, which is assumed to be a tar
  # file of some description (gzipped or plain), and unpacks it into
  # +destination+.
  def unzip(file_pattern, destination, options={})
    Dir.glob(file_pattern) do |fname|
      if File.readable?(fname) then
	target="/tmp/#{File.basename(fname)}"
	if MMAP
	  logger.debug "Using Memory Mapped File Upload"
	  fdata=Mmap.new(fname,"r", Mmap::MAP_SHARED, :advice => Mmap::MADV_SEQUENTIAL)
        else
	  fdata=File.open(fname).read
	end
	put(fdata, target, options)
	send run_method, <<-CMD
	  sh -c "cd #{destination} &&
	  zcat -f #{target} | tar xvf - &&
	  rm -f #{target}"
	CMD
      end
    end
  end
  
  # Wrap this around your task calls to catch the no servers error and
  # ignore it
  #    
  #    std.ignore_no_servers_error do
  #      activate_mysql
  #    end
  #    
  def ignore_no_servers_error (&block)
    begin
      yield
    rescue RuntimeError => failure
      if failure.message =~ /no servers matched/
	logger.debug "Ignoring 'no servers matched' error in task #{current_task.name}"
      else
	raise
      end
    end
  end

  # Wrap this around your task to force a connection as root.
  # Flushes the session cache before and after the connection.
  #
  #    std.connect_as_root do
  #      install_sudo
  #    end
  #
  def connect_as_root (&block)
    begin
      tempuser = user
      set :user, "root"
      actor.sessions.delete_if { true }
      yield tempuser
    ensure
      set :user, tempuser if tempuser
      actor.sessions.delete_if { true }
    end
  end

  #Returns a random string of alphanumeric characters of size +size+
  #Useful for passwords, usernames and the like.
  def random_string(size=10)
    s = ""
    size.times { s << (i = rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    s
  end


  # Return a relative path from the destination directory +from_str+
  # to the target file/directory +to_str+. Used to create relative
  # symbolic link paths.
  def relative_path (from_str, to_str) 
    require 'pathname'
    Pathname.new(to_str).relative_path_from(Pathname.new(from_str)).to_s
  end

  # Run a ruby command file on the servers 
  #
  def ruby(cmd, options={}, &block)
    temp_name = random_string + ".rb"
    begin
      put(cmd, temp_name, :mode => 0700)
      send(run_method, "ruby #{temp_name}", options, &block)
    ensure
      delete temp_name
    end
  end

  # Run a patchfile on the servers
  # Ignores reverses and rejects.
  #
  def patch(patchfile, level = '0', where = '/')
    temp_name = random_string
    begin
      fput(patchfile, temp_name, :mode => 0600)
      send(run_method, %{
        patch -p#{level} -tNd #{where} -r /dev/null < #{temp_name} || true
      })
    ensure
      delete temp_name
    end
  end

  # Deletes the given file(s) from all servers targetted by the current
  # task, but runs the +delete+ command according to the current setting
  # of <tt>:use_sudo</tt>.
  #
  # If <tt>:recursive => true</tt> is specified, it may be used to remove
  # directories.
  def su_delete(path, options={})
    cmd = "rm -%sf #{path}" % (options[:recursive] ? "r" : "")
    send(run_method, cmd, options)
  end

  # Render a template file and upload it to the servers
  # 
  def put_template(template, destination, options={})
    if MMAP
      logger.debug "Using Memory Mapped File Upload"
      fdata=Mmap.new(template,"r", Mmap::MAP_SHARED, :advice => Mmap::MADV_SEQUENTIAL)
    else
      fdata=File.read(template)
    end
    put(render(:template => fdata), destination, options)
  end

end

Capistrano.plugin :std, Std
#
# vim: nowrap sw=2 sts=2 ts=8 ff=unix ft=ruby:
