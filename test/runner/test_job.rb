require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/shared/testbot.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/runner/job.rb'))
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

module Testbot::Runner

  class JobTest < Test::Unit::TestCase

    def expect_put_with(id, result_text, success, time = 0.0)
      expected_result = "\n#{`hostname`.chomp}:#{Dir.pwd}\n"
      expected_result += result_text
      flexmock(Server).should_receive(:put).once.with("/jobs/#{id}", :body =>
                                                      { :result => expected_result, :success => success, :time => time })
    end

    def stub_duration(seconds)
      time ||= Time.now 
      flexmock(Time).should_receive(:now).and_return(time, time + seconds)
    end

    should "be able to run a successful job" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", true)
      flexmock(job).should_receive(:run_and_return_result).once.
        with("export RAILS_ENV=test; export TEST_ENV_NUMBER=; cd project; export RSPEC_COLOR=true; ruby -S rspec spec/foo_spec.rb spec/bar_spec.rb").
        and_return('result text')
      job.run(0)
    end

    should "return false on success if the job fails" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", false)
      flexmock(job).should_receive(:run_and_return_result).and_return('result text')
      flexmock(job).should_receive(:success?).and_return(false)
      job.run(0)
    end

    should "set an instance number when the instance is not 0" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", true)
      flexmock(job).should_receive(:run_and_return_result).
        with(/TEST_ENV_NUMBER=2/).
        and_return('result text')
      job.run(1)
    end

    should "return test runtime" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)

      stub_duration(10.55) 
      expect_put_with(10, "result text", true, 10.55)
      flexmock(job).should_receive(:run_and_return_result).and_return('result text')
      job.run(0)
    end

  end

end
