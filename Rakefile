# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "browshot"
  gem.homepage = "http://github.com/juliensobrier/browshot-ruby"
  gem.license = "MIT"
  gem.summary = "Ruby library for Browshot (L<http://www.browshot.com/>), a web service to create website screenshots."
  gem.description = "Browshot (http://www.browshot.com/) is a web service to easily make screenshots of web pages in any screen size, as any device: iPhone©, iPad©, Android©, Nook©, PC, etc. Browshot has full Flash, JavaScript, CSS, & HTML5 support. The latest API version is detailed at http://browshot.com/api/documentation. browshot.rb follows the API documentation very closely: the function names are similar to the URLs used (screenshot/create becomes screenshot_create(), instance/list becomes instance_list(), etc.), the request arguments are exactly the same, etc. The library version matches closely the API version it handles: browshot 1.0.0 is the first release for the API 1.0, browshot 1.1.1 is the second release for the API 1.1, etc. browshot.rb can handle most the API updates within the same major version, e.g. browshot.rb 1.0.0 should be compatible with the API 1.1 or 1.2."
  gem.email = "julien@sobrier.net"
  gem.authors = ["Julien Sobrier"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "browshot #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
