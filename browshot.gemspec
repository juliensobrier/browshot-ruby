Gem::Specification.new do |s|
  s.name        = 'browshot'
  s.version     = File.read(File.expand_path('VERSION', File.dirname(__FILE__))).strip
  s.summary     = "Take website screenshots with Browshot"
  s.description = "Library for the Browshot API"
  s.authors     = ["Julien Sobrier"]
  s.email       = 'julien@sobrier.net'
  s.files       = ["Gemfile", "Rakefile", "README.rdoc", "CHANGELOG.rdoc", "LICENSE.txt", "VERSION", "browshot.gemspec", "lib/browshot.rb"]
  s.require_paths = ["lib"]
  s.test_files  = Dir["test/*.rb"]
  s.homepage    = 'https://browshot.com/'
  s.license     = 'MIT'
  s.add_dependency "json"
  s.add_dependency "url"
  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "yard"
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'webrick'
end