# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path("lib/testbot")

Gem::Specification.new do |s|
  s.name        = "testbot"
  s.version     = Testbot.version
  s.authors     = ["Joakim Kolsjö"]
  s.email       = ["joakim.kolsjo@gmail.com"]
  s.homepage    = "http://github.com/joakimk/testbot"
  s.summary     = %q{A test distribution tool.}
  s.description = %q{Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber.}
  s.bindir      = "bin"
  s.executables = [ "testbot" ]
  s.files       = Dir.glob("lib/**/*") + %w(Gemfile testbot.gemspec CHANGELOG README.markdown bin/testbot) +
                  (File.exists?("DEV_VERSION") ? [ "DEV_VERSION" ] : [])
  s.add_dependency('sinatra', '=1.0.0') # To be able to use rack 1.0.1 which is compatible with rails 2.
  s.add_dependency('httparty', '>= 0.6.1')
  s.add_dependency('macaddr', '>= 1.0.0')
  s.add_dependency('net-ssh', '>= 2.0.23')
  s.add_dependency('sequel', '>= 3.16.0')
  s.add_dependency('json', '>= 1.4.6')
  s.add_dependency('daemons', '=1.0.10') # Because mongrel uses this version
  s.add_dependency('acts_as_rails3_generator')

  # Could work with older versions, but not newer (when deploying on debian)
  s.add_dependency('sqlite3-ruby', '= 1.2.5')

  # Because sinatra's "disable :logging" does not work with WEBrick.
  # Also, using a version that builds on ruby 1.9.2.
  s.add_dependency('mongrel', '1.2.0.pre2')  
end
