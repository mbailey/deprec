TEMPLATE_LOAD_PATH = []
TEMPLATE_LOAD_PATH << File.expand_path(
  File.join(File.dirname(__FILE__),'deprec','templates')
)
require 'deprec-core'

if defined?(Capistrano)
  Dir.glob("#{File.dirname(__FILE__)}/deprec/recipes/*.rb").each { |t| require t }
elsif defined?(Rake)
  Dir.glob("#{File.dirname(__FILE__)}/deprec/recipes/*.rake").each { |t| import t }
end
