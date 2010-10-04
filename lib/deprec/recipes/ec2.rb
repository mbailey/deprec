# Copyright 2006-2010 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do
    namespace :ec2 do
      
      set :ec2_zone, 'us-west-1'
 
      desc "Set some EC2 specific variables"
      task :default do
        unset :gateway
        ssh_options[:paranoid] = false
        set :network_dns_nameservers, '172.16.0.23' # valid outside us-west-1?
        set(:network_dns_search_path) {"#{ec2_zone}.compute.internal"}
        set :ec2_instance_id, 
          capture("curl http://169.254.169.254/latest/meta-data/instance-id")
      end

      desc "Disable termination of EC2 instances"
      task :safe do
        while true
          instanceid = ec2_instance_id ||
            Capistrano::CLI.ui.ask("instanceid") do |q|
              q.default = 'exit'
            end
          break if instanceid == 'exit'
          # Disable termination of this instance. Safety lock!
          `ec2-modify-instance-attribute --disable-api-termination true #{instanceid}`
          # Don't destroy EBS volume when instance terminated
          # This is default for EBS backed volumes but we want to be explicit. 
          `ec2-modify-instance-attribute --instance-initiated-shutdown-behavior stop #{instanceid}`
          break if ec2_instance_id # don't keep asking for instance id's 
        end
      end
 
    end 
  end
end
