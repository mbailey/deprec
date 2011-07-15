require 'deprec-core'
if defined?(Capistrano)
  require "#{File.dirname(__FILE__)}/deprec/cap"
elsif defined?(Rake)
  require "#{File.dirname(__FILE__)}/deprec/rake"
end
