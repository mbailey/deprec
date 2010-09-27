# =apt.rb: Debian 'apt' Installer library
# Capistrano plugin module to install and manage apt packages
#
# ----
# Copyright (c) 2007 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# = Purpose
# Apt is a Capistrano plugin module providing a set of methods
# that invoke the *apt* package manager (as used in Debian and Ubuntu)
#
# Installs within Capistrano as the plugin _apt_.
#
# =Usage
#    
#    require 'vmbuilder_plugins/apt'
#
# Prefix all calls to the library with <tt>apt.</tt>
#
module Apt 

  # Default apt-get command - reduces any interactivity to the minimum.
  APT_GET="DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get" 

  # Run the apt install program across the package list in 'packages'. 
  # Select those packages referenced by <tt>:base</tt> and the +version+
  # of the distribution you want to use.
  def install(packages, version, options={})
    update
    special_options="--allow-unauthenticated" if version != :stable
    send(run_method, %{
      sh -c "#{APT_GET} -qyu --force-yes #{special_options.to_s} install #{package_list(packages, version)}"
    }, options)
  end

  # Run an apt clean
  def clean(options={})
    send(run_method, %{sh -c "#{APT_GET} -qy clean"}, options)
  end

  # Run an apt autoclean
  def autoclean(options={})
    send(run_method, %{sh -c "#{APT_GET} -qy autoclean"}, options)
  end

  # Run an apt distribution upgrade
  def dist_upgrade(options={})
    update
    send(run_method, %{sh -c "#{APT_GET} -qy dist-upgrade"}, options)
  end

  # Run an apt upgrade. Use dist_upgrade instead if you want to upgrade
  # the critical base packages.
  def upgrade(options={})
    update
    send(run_method, %{sh -c "#{APT_GET} -qy upgrade"}, options)
  end

  # Run an apt update.
  def update(options={})
    send(run_method, %{sh -c "#{APT_GET} -qy update"}, options)
  end

  # RPM package install via alien
  def rpm_install(packages, options={})
    install({:base => %w(wget alien) }, :base)
    send(run_method, "wget -Ncq #{packages.join(' ')}", options)
    files=packages.collect { |package| File.basename(package) }
    send(run_method, "alien -i #{files.join(' ')}", options)
  end

  # Clear the source list and package cache
  def clear_cache(options={})
    clean
    cmd="rm -f /var/cache/apt/*.bin /var/lib/apt/lists/*_* /var/lib/apt/lists/partial/*"
    send(run_method, cmd, options)
  end

private

  # Provides a string containing all the package names in the base
  #list plus those in +version+.
  def package_list(packages, version)
    Array(packages[:base]).join(' ') + ' ' + Array(packages[version]).join(' ')
  end

end

Capistrano.plugin :apt, Apt
# vim: nowrap sw=2 sts=2 ts=8 ff=unix ft=ruby:
