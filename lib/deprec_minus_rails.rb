unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"

# Don't load the rails recipes in ~/.caprc
#
# This excludes the 'before' and 'after' tasks deprec adds to 
# facilitate rails setup.
require "#{File.dirname(__FILE__)}/deprec/recipes_minus_rails"