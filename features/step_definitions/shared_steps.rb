def create_app(version)
  if version.to_i == 3
    system "rails new #{@app_path} &> /dev/null" || raise('Failed to create rails3 fixture')
  else
    raise "Implement"
  end
end

def with_test_gemset
  begin
    system "rvm gemset use #{@test_gemset_name}"
    yield
  ensure
    system "rvm gemset use #{@current_gemset}"
  end
end

Given /^I have a rails (\d+) application$/ do |version|
  has_rvm = system "which rvm &> /dev/null"
  raise "You need rvm to run these tests as the tests use it to setup isolated environments." unless has_rvm
  
  system "rm -rf tmp/cucumber; mkdir -p tmp/cucumber"
  @test_gemset_name = "testbot_rails#{version}"
  @current_gemset = `rvm gemset name`.chomp
  @app_path = "tmp/cucumber/rails#{version}"

  has_gemset = `rvm gemset list|grep '#{@test_gemset_name}'` != ""
  if has_gemset
    with_test_gemset do
      create_app(version)
    end
  else
    puts "This test needs to setup a gemset in rvm for rails#{version} to test rails#{version} integration."
    puts "Do you want to continue? (y/N)"
    exit 0 unless STDIN.gets.chomp == 'y'

    system "rvm gemset create #{@test_gemset_name}"
    
    with_test_gemset do
      system "gem install rails -v 3.0.3 &> /dev/null" || raise("Failed to install rails#{version}")
      create_app(version)
    end
  end
end

Given /^I add testbot as a gem dependency$/ do
  system %{echo 'gem "testbot"' >> #{@app_path}/Gemfile}
end

Given /^I run "([^"]*)"$/ do |command|
  with_test_gemset do
    system "cd #{@app_path}; #{command} &> /dev/null"
  end
end

