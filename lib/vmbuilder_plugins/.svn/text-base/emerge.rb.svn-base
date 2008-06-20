# =emerge.rb: Gentoo 'emerge' Installer library
# Capistrano task library to install and manage portage packages
#
# Copyright (c) 2007 monki(Wesley Beary)
#
# inspiration: vmbuilder by Neil Wilson, Aldur Systems Ltd
#
# Licenced under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# =Purpose
# emerge is a Capistrano plugin module providing a set of methods
# that invoke the portage package manage (as used in Gentoo)
#
# Installs within Capistrano as the plugin _emerge_.
#
# =Usage
#
#   require 'marshall/plugins/emerge'
#
# Prefix all calls to the library with <tt>emerge.</tt>
#
module Emerge
  # Default emerge command - reduce interactivity to the minimum
  EMERGE="emerge -q"
  
  # Emerge a new package or packages
  def install(packages, options={})
    cmd = <<-CMD
    sh -c "#{EMERGE} #{packages.join(" ")}"
    CMD
    sudo(cmd, options)
  end
  
  # Run clean old/unused packages
  def clean(options={})
    cmd = <<-CMD
      sh -c "#{EMERGE} -clean"
    CMD
    sudo(cmd, options)
  end
  
  # Upgrade installed package list
  def upgrade(options={})
    cmd = <<-CMD
      sh -c "#{EMERGE} --sync"
    CMD
    sudo(cmd, options)
  end
  
  # Update portage
  def update_system(options={})
    cmd = <<-CMD
      sh -c "#{EMERGE} portage"
    CMD
    sudo(cmd, options)
  end
  
  # Update all installed packages
  def update(options={})
    cmd = <<-CMD
      sh -c "#{EMERGE} --update --deep --newuse world"
    CMD
    sudo(cmd, options)
  end
  
  # Boot script manipulation command
  def rc_update(packages, setting)
    packages.each do |service|
      sudo "rc_update add #{service} #{setting}"
    end
  end
end

Capistrano.plugin :emerge, Emerge
