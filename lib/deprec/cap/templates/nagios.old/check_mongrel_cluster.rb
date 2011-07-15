#!/usr/bin/env ruby  

require 'yaml'

# Exit status
OK = 0
WARNING = 1
CRITICAL = 2

# use options instead
application = ARGV[0]
cluster_config_file = "/etc/mongrel_cluster/#{application}.yml"

def running?(pid)
  # check if pid is running
  ps_output = `ps -p #{pid}`
  ps_output =~ /mongrel_rails/
end

def chdir_cwd
  pwd = Dir.pwd
  Dir.chdir(@options["cwd"]) if @options["cwd"]     
  yield
  Dir.chdir(pwd) if @options["cwd"]
end

def read_pid(port)
  pid_file = port_pid_file(port)
  pid = 0
  chdir_cwd do     
    pid = File.read(pid_file)
  end
  pid
end


# Load cluster config from YAML file
begin
  cluster_config = YAML.load_file(cluster_config_file)
  port = cluster_config['port'].to_i
  servers = cluster_config['servers']
  ports = (port..port+servers-1).collect
  if cluster_config['pid_file'].match(/^\//)
    pid_file_base = cluster_config['pid_file']
  else
    pid_file_base = File.join(cluster_config['cwd'], cluster_config['pid_file'])
  end
rescue
  print 'CRITICAL'
  puts " Could not load mongrel cluster file (#{cluster_config_file})"
  exit CRITICAL
end

# Check each mongrel
running = []
not_running = []

ports.each {|port|
  pidfile = pid_file_base.sub('.pid',".#{port}.pid")
  if File.readable?(pidfile)
    pid = File.read(pidfile)
    if running?(pid)
      running << port
    else
      not_running << port
    end
  else
    not_running << port
  end
} 

# Print response and exit

if not_running.empty?
  print 'OK '
  puts "mongrel running on ports #{running.join(', ')}"
  exit OK
else
  print 'CRITICAL '
  puts "mongrel not running on #{not_running.join(', ')}. #{'Running on ' + running.join(', ') unless running.empty?}"
  exit CRITICAL
end
