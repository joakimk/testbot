# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lib/testbot"

Gem::Specification.new do |s|
  s.name        = "testbot"
  s.version     = Testbot::VERSION
  s.authors     = ["Joakim Kolsjö"]
  s.email       = ["joakim.kolsjo@gmail.com"]
  s.homepage    = "http://github.com/joakimk/testbot"
  s.summary     = %q{A test distribution tool.}
  s.description = %q{Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber.}
  s.bindir      = "bin"
  s.executables = [ "testbot" ]
  s.files       = Dir.glob("lib/**/*") + %w(Gemfile testbot.gemspec CHANGELOG README.markdown bin/testbot)
end
