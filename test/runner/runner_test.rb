require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/shared/testbot.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/runner/runner.rb'))
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

module Testbot::Runner

  class RunnerTest < Test::Unit::TestCase
    should "use bundle exec in when calling rake testbot:before_run if bundler is present" do
      job = flexmock(:job, :project => "/path")
      flexmock(RubyEnv).should_receive(:bundler?).with("/path").returns(true)
      
      runner = Runner.new({:max_instances => 1})
      flexmock(File).should_receive(:exists?).with("/path/lib/tasks/testbot.rake").and_return(true)
      flexmock(File).should_receive(:exists?).with("/path/config/testbot/before_run.rb").and_return(false)
      flexmock(runner)
      flexmock(runner).should_receive(:system).with("cd /path; bundle").once
      flexmock(runner).should_receive(:system).with("cd /path; RAILS_ENV=test TEST_INSTANCES=1 bundle exec rake testbot:before_run").once
      runner.send(:before_run, job)
    end

    should "be able to use a plain ruby before_run file" do
      job = flexmock(:job, :project => "/path")
      flexmock(RubyEnv).should_receive(:bundler?).with("/path").returns(true)
      
      runner = Runner.new({:max_instances => 1})
      flexmock(File).should_receive(:exists?).with("/path/lib/tasks/testbot.rake").and_return(false)
      flexmock(File).should_receive(:exists?).with("/path/config/testbot/before_run.rb").and_return(true)
      flexmock(runner)
      flexmock(runner).should_receive(:system).with("cd /path; bundle").once
      flexmock(runner).should_receive(:system).with("cd /path; RAILS_ENV=test TEST_INSTANCES=1 bundle exec ruby config/testbot/before_run.rb").once
      runner.send(:before_run, job)
    end

    should "be able to run without bundler" do
      job = flexmock(:job, :project => "/path")
      flexmock(RubyEnv).should_receive(:bundler?).with("/path").returns(false)
      
      runner = Runner.new({:max_instances => 1})
      flexmock(File).should_receive(:exists?).with("/path/lib/tasks/testbot.rake").and_return(false)
      flexmock(File).should_receive(:exists?).with("/path/config/testbot/before_run.rb").and_return(true)
      flexmock(runner)
      flexmock(runner).should_receive(:system).with("cd /path; RAILS_ENV=test TEST_INSTANCES=1  ruby config/testbot/before_run.rb").once
      runner.send(:before_run, job)
    end 
  end
end

