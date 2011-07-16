require 'deprec-core'
if defined?(Capistrano)
  Dir.glob('deprec/recipes/*.rb').each { |t| require t }
elsif defined?(Rake)
  Dir.glob('deprec/recipes/*.rake').each { |t| import t }
end
