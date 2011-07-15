# deprec3 does not load deprec/recipes/rails.rb
#
# rails.rb originally provided callbacks for Capistrano's 
# deploy tasks. This was a cause of surprise for some 
# people so 'deprec_minus_rails' became a default for a 
# while.
#
# deprec_minus_rails is now..erm...deprecated
#
require "#{File.dirname(__FILE__)}/deprec"
