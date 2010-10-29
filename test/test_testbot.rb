require File.join(File.dirname(__FILE__), '../lib/testbot')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

module TestbotTestHelpers

  def requester_attributes
    { :server_uri => "http://192.168.0.100:2288",
      :server_type => 'rsync', :server_path => "/tmp/testbot/#{ENV['USER']}",
      :ignores => '', :available_runner_usage => "100%", :project => "project" }
  end  
  
end

class TestbotTest < Test::Unit::TestCase
    
  include TestbotTestHelpers
    
  context "self.run" do

    context "with no args" do
      should "return false" do
        assert_equal false, Testbot.run([])
      end   
    end
    
    context "with --help" do
      should "return false" do
        assert_equal false, Testbot.run([ '--help' ])
      end      
    end
    
    context "with --version" do
      should "print version and return true" do
        flexmock(Testbot).should_receive(:puts).once.with("Testbot #{Testbot::VERSION}")
        assert_equal true, Testbot.run([ '--version' ])
      end
    end
        
    context "with --server" do
      should "start a server" do
        flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID)
        flexmock(SimpleDaemonize).should_receive(:start).once.with(any, Testbot::SERVER_PID).and_return(1234)
        flexmock(Testbot).should_receive(:puts).once.with("Testbot server started (pid: 1234)")
        assert_equal true, Testbot.run([ "--server" ])
      end
    
      should "stop a server when stop is passed" do
        flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID).and_return(true)
        flexmock(Testbot).should_receive(:puts).once.with("Testbot server stopped")
        assert_equal true, Testbot.run([ "--server", "stop" ])
      end
    
      should "not print when SimpleDaemonize.stop returns false" do
        flexmock(SimpleDaemonize).should_receive(:stop).and_return(false)
        flexmock(Testbot).should_receive(:puts).never
        Testbot.run([ "--stop", "server" ])
      end
    end
  
    context "with --runner" do
      should "start a runner" do
        flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID)
        flexmock(SimpleDaemonize).should_receive(:start).once.with(any, Testbot::RUNNER_PID).and_return(1234)
        flexmock(Testbot).should_receive(:puts).once.with("Testbot runner started (pid: 1234)")
        assert_equal true, Testbot.run([ "--runner", "--connect", "192.168.0.100", "--working_dir", "/tmp/testbot" ])
      end
      
      should "stop a runner when stop is passed" do
        flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID).and_return(true)
        flexmock(Testbot).should_receive(:puts).once.with("Testbot runner stopped")
        assert_equal true, Testbot.run([ "--runner", "stop" ])
      end
      
      should "return false without connect" do
        assert_equal false, Testbot.run([ "--runner", "--connect" ])
        assert_equal false, Testbot.run([ "--runner" ])
      end
    end
    
    Adapter.all.each do |adapter|
      context "with --#{adapter.type}" do
        should "start a #{adapter.name} requester and return true" do
          flexmock(Requester).should_receive(:new).once.
                              with(requester_attributes).and_return(mock = Object.new)
          flexmock(mock).should_receive(:run_tests).once.with(adapter, adapter.base_path)
          assert_equal true, Testbot.run([ "--#{adapter.type}", "--connect", "192.168.0.100" ])
        end
        
        should "accept a custom server_path" do
          flexmock(Requester).should_receive(:new).once.
                              with(requester_attributes.merge({ :server_path => "/somewhere/else" })).
                              and_return(mock = Object.new)
          flexmock(mock).should_receive(:run_tests)
          Testbot.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--server_path', '/somewhere/else' ])
        end
        
        should "accept ignores" do
          flexmock(Requester).should_receive(:new).once.
                              with(requester_attributes.merge({ :ignores => "tmp log" })).
                              and_return(mock = Object.new)
          flexmock(mock).should_receive(:run_tests)
          Testbot.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--ignores', 'tmp log' ])
        end
      end
    end
  end
    
  context "self.parse_args" do

    should 'convert ARGV arguments to a hash' do
      hash = Testbot.parse_args("--runner --connect http://127.0.0.1:2288 --working_dir ~/testbot --ssh_tunnel user@testbot_server".split)
      assert_equal ({ :runner => true, :connect => "http://127.0.0.1:2288", :working_dir => "~/testbot", :ssh_tunnel => "user@testbot_server" }), hash
    end
    
    should "handle just a key without a value" do
      hash = Testbot.parse_args([ "--server" ])
      assert_equal ({ :server => true }), hash
    end
    
  end
  
end