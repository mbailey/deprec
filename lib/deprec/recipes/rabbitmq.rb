Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :rabbitmq do

      set :rabbtimq_user_uid, 899
      set :rabbitmq_apt_key, "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
      set :rabbitmq_plugins, [
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/mochiweb-1.3-rmq2.5.0-git9a53dbd.ez",
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/webmachine-1.7.0-rmq2.5.0-hg0c4b60a.ez",
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/amqp_client-2.5.0.ez",
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/rabbitmq_mochiweb-2.5.0.ez",
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/rabbitmq_management_agent-2.5.0.ez",
        "http://www.rabbitmq.com/releases/plugins/v2.5.0/rabbitmq_management-2.5.0.ez"
      ]
      set :rabbitmq_plugins_dir, "/usr/lib/rabbitmq/lib/rabbitmq_server-2.5.0/plugins"
      set :rabbitmq_port, 5672
      set :rabbitmq_mochiweb_port, 55672

      desc "Install RabbitMq 2.5.0"
      task :install do
        create_user
        apt.add_source "deb http://www.rabbitmq.com/debian/ testing main", "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
        apt.install( {:base => %w(rabbitmq-server=2.5.0-1)}, :stable )
        set_erlang_cookie
        install_plugins
        config
      end

      desc "Create rabbitmq user, and group (with specific uid)"
      task :create_user do
        sudo "addgroup --system --gid #{rabbtimq_user_uid} rabbitmq"
        sudo "adduser  --system --uid #{rabbtimq_user_uid} -gid #{rabbtimq_user_uid} rabbitmq"
        logger.debug "rabbitmq user: #{capture("id rabbitmq")}"
      end

      desc "Copy .erlang.cookie file to rabbitmq users home"
      task :set_erlang_cookie do
        file = "/home/rabbitmq/.erlang.cookie"
        deprec2.render_template(:rabbitmq, {:template => ".erlang.cookie", :remote => true, :mode => 0400, :owner => "rabbitmq", :path => file} )
        sudo "chgrp rabbitmq #{file}"
      end

      desc "Install RabbitMq plugins"
      task :install_plugins do
        rabbitmq_plugins.each do |url|
          run "cd #{rabbitmq_plugins_dir} && test -f #{File.basename(url)} || #{sudo} wget --quiet --timestamping #{url}"
        end
      end

      desc "Create rabbitmq.config file from template"
      task :config do
        deprec2.render_template(:rabbitmq, {:template => "rabbitmq.config", :remote => true, :path => "/etc/rabbitmq/rabbitmq.config", :mode => 0644, :owner => 'root'} )
      end


      desc "Start RabbitMq"
      task :start do
        send(run_method, "/etc/init.d/rabbitmq-server start")
      end

      desc "Stop RabbitMq"
      task :stop do
        send(run_method, "/etc/init.d/rabbitmq-server stop")
      end

      desc "Restart RabbitMq"
      task :restart do
        send(run_method, "/etc/init.d/rabbitmq-server restart")
      end

    end
  end
end
