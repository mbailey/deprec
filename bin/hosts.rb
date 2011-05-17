#!/usr/bin/env ruby
#
# Generate Nagios hosts files from unix hosts file
#
# e.g.
# 10.1.1.1 gw.failmode.com
# 10.1.1.5 mail.failmode.com 

require 'erb'

hosts_file = ARGV[0] || '/etc/hosts'

template = ERB.new <<-EOF
define host{
  use        generic-host
  hostgroups linux-servers
  host_name  <%= host_name %>
  address    <%= ip %>
}
EOF

ValidIpAddressRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/;

ValidHostnameRegex = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/;

# XXX Add hostgroups to hosts
# HOSTGROUPS = 'linux-servers', 'windows-servers', 'debian-servers', 'vmware-hosts'

open(hosts_file).each do |line| 
  ip, host_name = line.sub(/#.*/,'').split[0,2]
  hostgroups = []


  if ip =~ ValidIpAddressRegex and host_name =~ ValidHostnameRegex
    filename = host_name + '.cfg'
    File.open(filename, 'w') do |file|
      file.write template.result(binding)
      puts "writing #{filename}"
    end
  else
    puts "not writing anything for '#{line}'"
  end

end
