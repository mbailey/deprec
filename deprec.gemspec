require 'rubygems' 

SPEC = Gem::Specification.new do |s|
  s.name = 'deprec'
  s.version = '2.1.5'
  
  s.authors = ['Mike Bailey']
  s.description = <<-EOF
      This project provides libraries of Capistrano tasks and extensions to 
      remove the repetative manual work associated with installing services 
      on linux servers.
  EOF
  s.email = 'mike@bailey.net.au'
  s.homepage = 'http://www.deprec.org/'
  s.rubyforge_project = 'deprec'
  s.summary = 'deployment recipes for capistrano'

  s.require_paths = ['lib']
  s.add_dependency('capistrano', '> 2.5.0')
  candidates = Dir.glob("{bin,docs,lib}/**/*") 
  candidates.concat(%w(CHANGELOG COPYING LICENSE README THANKS))
  s.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  s.default_executable = "depify"
  s.executables = ["depify"]
end
