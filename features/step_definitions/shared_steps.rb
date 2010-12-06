require 'rvm'

def rails3?
  @version[0, 1].to_i == 3
end

def create_app
  system("gem install #{find_latest_gem} 1> /dev/null") || raise("Testbot install failed")
  if rails3? 
    system("rails new #{@app_path} 1> /dev/null") || raise('Failed to create rails3 app')
  else
    system("rails #{@app_path} 1> /dev/null") || raise("Failed to create rails2 app")
  end
end

def find_latest_gem
  [ "pkg", Dir.entries("pkg").reject { |file| file[0,1] == '.' }.sort_by { |file| File.mtime("pkg/#{file}") }.last ].join('/')
end

def use_test_gemset!
  RVM.gemset_use! @test_gemset_name
end

def use_normal_gemset!
  RVM.gemset_use! 'testbot'
end

Given /^I have a rails (.+) application$/ do |version|
  use_normal_gemset!

  has_rvm = system "which rvm > /dev/null"
  raise "You need rvm to run these tests as the tests use it to setup isolated environments." unless has_rvm
  
  system "rm -rf tmp; mkdir -p tmp"
  
  @version = version
  @test_gemset_name = "testbot_rails_#{@version}"
  @testbot_path = Dir.pwd
  @app_path = "tmp/cucumber/rails_#{@version}"

  system "rake build 1> /dev/null" 
  
  has_gemset = `rvm gemset list|grep '#{@test_gemset_name}'` != ""
  if has_gemset
    use_test_gemset!
  else
    system "rvm gemset create #{@test_gemset_name} 1> /dev/null"
    
    use_test_gemset!
    system("gem install rails -v #{@version} --no-ri --no-rdoc 1> /dev/null") || raise("Failed to install rails#{@version}")
  end
  create_app
end

Given /^I add testbot$/ do
  if rails3?
    system %{echo 'gem "testbot"' >> #{@app_path}/Gemfile}
  else
    system %{cd #{@app_path}; ln -s #{@testbot_path} vendor/plugins/testbot}
  end
end

And /^I add rspec 2 and some specs$/ do
  system %{echo "gem 'rspec-rails', '~> 2.0.1'" >> #{@app_path}/Gemfile}
  And 'I run "gem install rspec-rails -v 2.0.1 --no-ri --no-rdoc"'
  And 'I run "script/rails generate rspec:install"'
  And 'I run "script/rails generate scaffold user name:string"'
end

Given /^I have a testbot network setup$/ do
  system "export INTEGRATION_TEST=true; testbot --server 1> /dev/null"
  system "export INTEGRATION_TEST=true; testbot --runner --connect 127.0.0.1 --working_dir #{@testbot_path}/tmp/runner 1> /dev/null"

  # Ignoring Gemfile.lock because bundle within the runner fails otherwise.
  # Seems the runner uses the "testbot" gemset even though its started with
  # the testing gemset... why is this?
  system "cd #{@app_path}; rails g testbot --connect 127.0.0.1 --rsync_ignores Gemfile.lock --rsync_path #{@testbot_path}/tmp/server 1> /dev/null"

  # Add db setup to testbot.rake
  lines = File.readlines("#{@app_path}/lib/tasks/testbot.rake")
  file = File.open("#{@app_path}/lib/tasks/testbot.rake", "w")
  lines.each do |line|
    file.write(line)
    if line.include?("task :before_run")
      file.write("system 'rake db:migrate'\n")
    end
  end
  file.close

  # Wait for the runner to register with the server
  sleep 2
end

Given /^I can successfully run "([^"]*)"$/ do |cmd|
  success = system("cd #{@app_path}; export INTEGRATION_TEST=true; #{cmd} 1> /dev/null")
  system "export INTEGRATION_TEST=true; testbot --server stop 1> /dev/null"
  system "export INTEGRATION_TEST=true; testbot --runner stop 1> /dev/null"
  system "rm -rf #{@testbot_path}/tmp"
  raise "Command failed!" unless success
end

Given /^I run "([^"]*)"$/ do |command|
  system("cd #{@app_path}; #{command} 1>/dev/null") || raise("Command failed.")
end

Then /^there is a "([^"]*)" file$/ do |path|
  File.exists?([ @app_path, path ].join('/')) || raise("File missing")
end

Then /^the "([^"]*)" file contains "([^"]*)"$/ do |path, content|
  File.read([ @app_path, path ].join('/')).include?(content) || raise("#{path} did not contain #{content}")
end

Then /^the testbot rake tasks are present$/ do
  rake_tasks = `cd #{@app_path}; rake -T testbot`
  raise unless rake_tasks.include?('rake testbot:test')
end

