if defined?(Capistrano)
  require "#{File.dirname(__FILE__)}/deprec/capistrano_extensions"
  require "#{File.dirname(__FILE__)}/vmbuilder_plugins/all"
  require "#{File.dirname(__FILE__)}/deprec/recipes"
elsif defined?(Rake)
  require "#{File.dirname(__FILE__)}/deprec/rake"
end
