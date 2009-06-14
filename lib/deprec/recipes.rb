# Copyright 2006-2008 by Mike Bailey. All rights reserved.
unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end

require "#{File.dirname(__FILE__)}/recipes_minus_rails"
require "#{File.dirname(__FILE__)}/recipes/rails"