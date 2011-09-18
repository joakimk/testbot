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
      flexmock(runner)
      flexmock(runner).should_receive(:system).with("export RAILS_ENV=test; export TEST_INSTANCES=1; cd /path; bundle; bundle exec rake testbot:before_run").once
      runner.send(:before_run, job)
    end
  end
end

