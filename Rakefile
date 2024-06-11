#!/usr/bin/env rake
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

# GENERATE AN UPDATED GEMSPEC FILE by running rake gemspec
require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "passbook2"
  gem.homepage = "https://github.com/masukomi/passbook"
  gem.license = "MIT"
  gem.summary = %Q{An Apple Passbook generator.}
  gem.description = %Q{This gem allows you to create Apple Passbooks.  This works with Rails but does not require it.}
  gem.email = ['thomas@lauro.fr', 'lgleason@polyglotprogramminginc.com', 'masukomi@masukomi.org']
  gem.authors = ['Thomas Lauro', 'Lance Gleason', 'Kay Rhodes']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new
# END GENERATE AN UPDATED GEMSPEC FILE

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
