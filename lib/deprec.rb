require 'deprec-core'
if defined?(Capistrano)
  Dir.glob("#{File.dirname(__FILE__)}/deprec/recipes/*.rb").each { |t| require t }
elsif defined?(Rake)
  Dir.glob("#{File.dirname(__FILE__)}deprec/recipes/*.rake").each { |t| import t }
end
