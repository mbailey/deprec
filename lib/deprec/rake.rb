$VERBOSE = nil

# Load deprec rake tasks
if defined?(Rake)
  %w(
    db
  ).each do |task|
    load File.join(File.dirname(__FILE__), 'recipes', "#{task}.rake")
  end
end

