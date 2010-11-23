require 'bundler'
require 'cucumber'
require 'cucumber/rake/task'

Bundler::GemHelper.install_tasks

task :default => [ :test, :features ] do
end

desc "Run Test::Unit tests"
task :test do
  Dir["test/**/test_*.rb"].each { |test| require(File.expand_path(test)) }
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end

# HACK: As we use RVM to install gems while running cucumber we don't want bundler
# to raise an error like "rails is not part of the bundle. Add it to Gemfile.".
module Cucumber::Rake
  class Task::ForkedCucumberRunner
    def runner
      [ RUBY ]
    end
  end
end
