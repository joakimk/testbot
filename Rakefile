require 'bundler'
# TODO: Add when possible. Currently "rake features" fails.
# require 'bundler/setup'
require 'cucumber'
require 'cucumber/rake/task'

Bundler::GemHelper.install_tasks

task :default => [ :test, :features ] do
end

desc "Run Test::Unit tests"
task :test do
  Dir["test/**/test_*.rb"].each { |test| require(File.expand_path(test)) }
end

desc "Used for quickly deploying and testing updates without pusing to rubygems.org"
task :deploy do
  File.open("DEV_VERSION", "w") { |f| f.write(".DEV.#{Time.now.to_i}") }
  
  gem_file = "testbot-#{Testbot.version}.gem"
  config = YAML.load_file(".deploy_config.yml")
  Rake::Task["build"].invoke
  
  begin
    system(config["upload_gem"].gsub(/GEM_FILE/, gem_file)) || fail
    system(config["update_and_restart_server"].gsub(/GEM_FILE/, gem_file)) || fail
  ensure
    system("rm DEV_VERSION")
  end
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
