# -*- encoding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/lib/shared/version')

Gem::Specification.new do |s|
  s.name        = "testbot"
  s.version     = Testbot.version
  s.authors     = ["Joakim Kolsjö"]
  s.email       = ["joakim.kolsjo@gmail.com"]
  s.homepage    = "http://github.com/joakimk/testbot"
  s.summary     = %q{A test distribution tool.}
  s.description = %q{Testbot is a test distribution tool that works with Rails, RSpec, RSpec2, Test::Unit and Cucumber.}
  s.bindir      = "bin"
  s.executables = [ "testbot" ]
  s.files       = Dir.glob("lib/**/*") + Dir.glob("test/**/*") + %w(Gemfile .gemtest Rakefile testbot.gemspec CHANGELOG README.markdown bin/testbot) +
                  (File.exists?("DEV_VERSION") ? [ "DEV_VERSION" ] : [])

  s.add_dependency('sinatra', '~> 1.0')
  s.add_dependency('httparty', '>= 0.6.1')
  s.add_dependency('net-ssh', '>= 2.0.23')
  s.add_dependency('json_pure', '>= 1.4.6')
  s.add_dependency('daemons', '>= 1.0.10')
  s.add_dependency('acts_as_rails3_generator')
  s.add_dependency('posix-spawn', '>= 0.3.6')

  s.add_development_dependency("shoulda")
  s.add_development_dependency("rack-test")
  s.add_development_dependency("flexmock")
  s.add_development_dependency("rvm")
  s.add_development_dependency("rake", "0.8.7")
  s.add_development_dependency("bundler")
  s.add_development_dependency("guard")
  s.add_development_dependency("guard-test")
end

