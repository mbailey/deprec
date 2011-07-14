$VERBOSE = nil

# Load deprec rakefile extensions
%w(
  db
  environments
).each do |task|
  load "deprec/rake/#{task}.rake"
end

