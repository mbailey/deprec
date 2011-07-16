require 'deprec-core'
if defined?(Capistrano)
  Dir.glob('deprec/recipes/*.rb').each { |t| puts t; require t }
  # require "#{File.dirname(__FILE__)}/deprec/cap"
elsif defined?(Rake)
  Dir.glob('deprec/recipes/*.rake').each { |t| puts t; import t }
  # require "#{File.dirname(__FILE__)}/deprec/rake"
end
