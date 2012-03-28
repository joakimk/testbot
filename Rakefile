require 'bundler'

Bundler::GemHelper.install_tasks

task :default => [ :test ] do
end

desc "Run Test::Unit tests"
task :test do
  Dir["test/**/*_test.rb"].each { |test| require(File.expand_path(test)) }
end


desc "Used for quickly deploying and testing updates without pusing to rubygems.org"
task :deploy do
  File.open("DEV_VERSION", "w") { |f| f.write(".DEV.#{Time.now.to_i}") }
  
  gem_file = "testbot-#{Testbot.version}.gem"
  config = YAML.load_file(".deploy_config.yml")
  Rake::Task["build"].invoke
  
  begin
    system(config["upload_gem"].gsub(/GEM_FILE/, gem_file)) || fail
    system(config["update_server"].gsub(/GEM_FILE/, gem_file)) || fail
    system(config["restart_server"]) || fail
  ensure
    system("rm DEV_VERSION")
  end
end

desc "Used to restart the server when developing testbot"
task :restart do
  config = YAML.load_file(".deploy_config.yml")
  system(config["restart_server"]) || fail
end
