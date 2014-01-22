Gem::Specification.new do |s|
  s.name        = 'browshot'
  s.version     = '1.14.0'
  s.date        = '2014-01-20'
  s.summary     = "Take website screenshtos with Browshot"
  s.description = "Library for the Browshot API"
  s.authors     = ["Julien Sobrier"]
  s.email       = 'julien@sobrier.net'
  s.files       = ["Gemfile", "Rakefile", "lib/browshot.rb"]
  s.require_paths = ["lib"]
  s.test_files  = ["test/helper.rb", "test/test_browshot.rb"]
  s.homepage    = 'https://browshot.com/'
  s.license     = 'MIT'
  s.add_dependency "json"
  s.add_dependency "url"
  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "yard"
end