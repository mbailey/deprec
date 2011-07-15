require 'deprec-core'
if defined?(Capistrano)
  require "#{File.dirname(__FILE__)}/deprec/recipes"
elsif defined?(Rake)
  require "#{File.dirname(__FILE__)}/deprec/rake"
end
