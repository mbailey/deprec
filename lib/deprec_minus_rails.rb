puts <<-EOF
    DEPRECATION WARNING!

    rails.rb originally provided callbacks for Capistrano's 
    deploy tasks. This was a cause of surprise for some 
    people so 'deprec_minus_rails' became a safe default 
    way for people to load deprec.

    deprec3 does not load deprec/recipes/rails.rb
    so deprec_minus_rails is now..erm...deprecated

    You should replace:

      require 'deprec_minus_rails'

    with:

      require 'deprec'

EOF

require "#{File.dirname(__FILE__)}/deprec"
