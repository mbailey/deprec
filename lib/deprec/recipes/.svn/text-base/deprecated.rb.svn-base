# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  
  # deprecated tasks from deprec1
  # we're now using namespaces and some different naming conventions
  
  # XXX use deprecated function to generate these dynamically
  
  deprec2_isnt_backwards_compatible = <<-EOF
    
You've installed deprec2 but seem to be using a deprec1 command.

You have two options:

- install deprec-1.9.x and continue using deprec1

  Instructions are available at http://www.deprec.org/

- use deprec2

EOF

  cap2_warning = <<-EOF
  
You're using Capistrano 2 but using a deprecated cap1 command.

EOF
  
  task :setup_admin_account do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap setup_admin_account' with 'cap deprec:users:add'"
    puts
  end
  
  task :change_root_password do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap change_root_password' with 'cap deprec:users:passwd'"
    puts
  end
  
  task :setup_ssh_keys do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap setup_ssh_keys' with 'cap deprec:ssh:setup_keys'"
    puts
  end
  
  task :install_rails_stack do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap install_rails_stack' with 'cap deprec:rails:install_rails_stack'"
    puts
  end
  
  task :setup do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap setup' with 'cap deploy:setup'"
    puts
  end
  
  task :restart_apache do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap restart_apache' with 'cap deprec:apache:restart'"
    puts
  end
  
  task :show_tasks do
    puts deprec2_isnt_backwards_compatible  
    puts "  Replace 'cap show-tasks' with 'cap -T'"
    puts
  end
  
end