require File.join(File.dirname(__FILE__), '../lib/testbot.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class TestbotTest < Test::Unit::TestCase
    
  context "self.run" do

    context "with no args" do
      should "return false" do
        assert_equal false, Testbot.run([])
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
      
      should "do return false with unsufficient args" do
        assert_equal false, Testbot.run([ "--runner", "--connect", "192.168.0.100", "--working_dir" ])
        assert_equal false, Testbot.run([ "--runner", "--connect", "192.168.0.100" ])        
        assert_equal false, Testbot.run([ "--runner", "--connect", "--working_dir", "/tmp/testbot" ])
        assert_equal false, Testbot.run([ "--runner", "--working_dir", "/tmp/testbot" ])
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