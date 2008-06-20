# =all.rb: Load all the Capistrano Plugins in the directory.
#
# Require all other ruby files in the directory.
#
# ----
# Copyright (c) 2007 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.
# ----
# = Usage
#
#     require 'vmbuilder_plugins/all'

# Splitting and joining __FILE__ deals with the current directory case
# properly
Dir[File.join( File.dirname(__FILE__), '*.rb')].each do |plugin_name|
  unless plugin_name == File.join(File.dirname(__FILE__), File.basename(__FILE__))
    require plugin_name
  end
end
