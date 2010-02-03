require File.join(File.dirname(__FILE__), '../lib/new_runner.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class NewRunnerTest < Test::Unit::TestCase
    
  should "query the server for jobs and run them" do
    flexmock(Server).should_receive(:get).once.with("/jobs/next").
                     and_return('10,server:/tmp/testbot/user,spec/models/car_spec.rb spec/models/house_spec.rb')
    flexmock(NewRunner).should_receive(:run_and_return_results).once.with("export RAILS_ENV=test; export RSPEC_COLOR=true; rake testbot:before_run; script/spec -O spec/spec.opts spec/models/car_spec.rb spec/models/house_spec.rb")
    flexmock(Server).should_receive(:put)
    NewRunner.run_jobs
  end
  
  should "return the result of a job to the server" do
    flexmock(Server).should_receive(:get).and_return('10,server:/tmp/testbot/user,spec/models/boat_spec.rb')
    flexmock(NewRunner).should_receive(:run_and_return_results).and_return('job result')
    flexmock(Server).should_receive(:put).once.with("/jobs/10", :body => { :result => 'job result' })
    NewRunner.run_jobs
  end
  
  should "not do anything if there is no job" do
    flexmock(Server).should_receive(:get)
    NewRunner.run_jobs
  end
  
  should "not do anything if the server does not respond" do
    flexmock(Server).should_receive(:get).and_raise('error')
    NewRunner.run_jobs
  end
  
end

class ServerTest < Test::Unit::TestCase
  
  should 'include HTTParty' do
    assert Server.new.kind_of?(HTTParty)
  end
  
  should 'configure the server uri' do
    flexmock(YAML).should_receive(:load_file).once.with("#{ENV['HOME']}/.testbot_runner.yml").
                   and_return({ :server_uri => 'http://somewhere:2288' })
    NewRunner.load_config
    assert_equal 'http://somewhere:2288', Server.base_uri
  end
  
end