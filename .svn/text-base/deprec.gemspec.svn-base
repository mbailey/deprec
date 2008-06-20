require 'rubygems' 

SPEC = Gem::Specification.new do |spec|
  spec.name = 'deprec'
  spec.author = 'Mike Bailey'
  spec.email = 'mike@bailey.net.au'
  spec.homepage = 'http://www.deprec.org/'
  spec.rubyforge_project = 'deprec'
  spec.version = '1.99.21'
  spec.summary = 'deployment recipes for capistrano'
  spec.description = <<-EOF
      This project provides libraries of Capistrano tasks and extensions to 
      remove the repetative manual work associated with installing services 
      on linux servers.
  EOF
  spec.require_path = 'lib'
  spec.add_dependency('capistrano', '> 2.0.0')
  candidates = Dir.glob("{bin,docs,lib}/**/*") 
  candidates.concat(%w(CHANGELOG COPYING LICENSE README THANKS))
  spec.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  spec.default_executable = "depify"
  spec.executables = ["depify"]
end
