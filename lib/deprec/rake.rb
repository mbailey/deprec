$VERBOSE = nil

# Load deprec rakefile extensions
if defined?(Rake)
  %w(
    db
    environments
  ).each do |task|
    load File.join(File.dirname(__FILE__), 'rake', "#{task}.rake")
  end
end

