# # Copyright 2006-2009 by Mike Bailey. All rights reserved.
# Capistrano::Configuration.instance(:must_exist).load do 
#   namespace :deprec do
#     namespace :haproxy do
#       
#       SRC_PACKAGES[:haproxy] = {
#         :md5sum => "e37046e0cb2f407d92c41d7731d1dd10  haproxy-1.3.20.tar.gz",  
#         :url => "http://haproxy.1wt.eu/download/1.3/src/haproxy-1.3.20.tar.gz"
#       }
#       
#       desc "Install haproxy"
#       task :install do
#         install_deps
#         deprec2.download_src(SRC_PACKAGES[:haproxy], src_dir)
#         deprec2.install_from_src(SRC_PACKAGES[:haproxy], src_dir)
#       end
#       
#       task :install_deps do
#         apt.install( {:base => %w(build-essential)}, :stable )
#       end
#       
#       SYSTEM_CONFIG_FILES[:haproxy] = [
#         
#         # {:template => "example.conf.erb",
#         #  :path => '/etc/example/example.conf',
#         #  :mode => 0755,
#         #  :owner => 'root:root'}
#          
#       ]
# 
#       PROJECT_CONFIG_FILES[:haproxy] = [
#         
#         # {:template => "example.conf.erb",
#         #  :path => 'conf/example.conf',
#         #  :mode => 0755,
#         #  :owner => 'root:root'}
#       ]
#       
#       
#       desc "Generate configuration file(s) for XXX from template(s)"
#       task :config_gen do
#         config_gen_system
#         config_gen_project
#       end
# 
#       task :config_gen_system do
#         SYSTEM_CONFIG_FILES[:haproxy].each do |file|
#           deprec2.render_template(:haproxy, file)
#         end
#       end
# 
#       task :config_gen_project do
#         PROJECT_CONFIG_FILES[:haproxy].each do |file|
#           deprec2.render_template(:haproxy, file)
#         end
#       end
#       
#       desc 'Deploy configuration files(s) for XXX' 
#       task :config, :roles => :web do
#         config_system
#         config_project
#       end
# 
#       task :config_system, :roles => :web do
#         deprec2.push_configs(:haproxy, SYSTEM_CONFIG_FILES[:haproxy])
#       end
# 
#       task :config_project, :roles => :web do
#         deprec2.push_configs(:haproxy, PROJECT_CONFIG_FILES[:haproxy])
#       end
#       
#       
#       task :start, :roles => :web do
#         run "#{sudo} /etc/init.d/haproxy start"
#       end
#       
#       task :stop, :roles => :web do
#         run "#{sudo} /etc/init.d/haproxy stop"
#       end
#       
#       task :restart, :roles => :web do
#         run "#{sudo} /etc/init.d/haproxy restart"
#       end
#       
#       task :reload, :roles => :web do
#         run "#{sudo} /etc/init.d/haproxy reload"
#       end
#       
#       task :activate, :roles => :web do
#         run "#{sudo} update-rc.d haproxy defaults"
#       end  
#       
#       task :deactivate, :roles => :web do
#         run "#{sudo} update-rc.d -f haproxy remove"
#       end
#       
#       task :backup, :roles => :web do
#       end
#       
#       task :restore, :roles => :web do
#       end
#       
#     end
#   end
# end