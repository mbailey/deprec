Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :erlang do

      #you can find md5 sums at: http://www.erlang.org/download/MD5
      SRC_PACKAGES[:erlang] = {
        :md5sum => "7979e662d11476b97c462feb7c132fb7  otp_src_R14B03.tar.gz",
        :url => "http://www.erlang.org/download/otp_src_R14B03.tar.gz"
      }

      #checking if specific Erlang version is already installed
      #versin is ok if erl -version returns string which ends with "emulator version 5.8.4"
      VERSION_CHECK = {
        :command => "erl -version; true",
        :should_return => /emulator version 5.8.4/
      }

      desc "Install Erlang"
      task :install do
        if version_ok?
          logger.debug "Erlang version ok, nothing to do."
        else
          install_deps
          deprec2.download_src(SRC_PACKAGES[:erlang], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:erlang], src_dir)
        end
      end

      desc "Prints currently installed Erlang version"
      task :version do
        ok = version_ok?
        logger.debug "Erlang version '#{@version}' #{ok ? "Ok" : "NOT ok"}."
      end

      desc "Install Erlang dependencies"
      task :install_deps do
        apt.install( {:base => %w(build-essential m4 libncurses5-dev libssh-dev unixodbc-dev libgmp3-dev libwxgtk2.8-dev libglu1-mesa-dev fop xsltproc default-jdk)}, :stable )
      end

      def version_ok?
        @version =  capture(VERSION_CHECK[:command]).gsub(/[\r\n]/,'')
        (@version =~ VERSION_CHECK[:should_return])
      end

    end
  end
end
