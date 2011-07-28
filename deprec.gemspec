$:.push File.expand_path("../lib", __FILE__)
require "deprec/version"

SPEC = Gem::Specification.new do |s|
  s.name = 'deprec'
  s.version = Deprec::VERSION
  
  s.authors = ['Mike Bailey']
  s.description = <<-EOF
      This project provides Capistrano and Rake tasks to 
      assist with deployment and configuration management
      on ubuntu linux servers.
  EOF
  s.email = 'mike@bailey.net.au'
  s.homepage = 'http://deprec.org/'
  s.rubyforge_project = 'deprec'
  s.summary = 'deployment recipes for capistrano'

  s.require_paths = ['lib']
  s.add_dependency('deprec-core', '>= 3.1.8')
  candidates = Dir.glob("{bin,docs,lib,rake}/**/*") 
  candidates.concat(%w(CHANGELOG COPYING LICENSE README.md THANKS))
  s.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  s.default_executable = "depify"
  s.executables = ["depify"]
end
