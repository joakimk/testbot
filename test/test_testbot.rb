require File.join(File.dirname(__FILE__), '../lib/testbot.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class TestbotTest < Test::Unit::TestCase
    
  context "self.run" do
    
    should "start a server and when --server is passed" do
      flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID)
      flexmock(SimpleDaemonize).should_receive(:start).once.with(/ruby.+lib\/server.rb -e production/, Testbot::SERVER_PID).and_return(1234)
      flexmock(Testbot).should_receive(:puts).once.with("Testbot server started (pid: 1234)")
      assert_equal true, Testbot.run([ "--server" ])
    end
    
    should "stop a server when --server stop is passed" do
      flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID).and_return(true)
      flexmock(Testbot).should_receive(:puts).once.with("Testbot server stopped")
      assert_equal true, Testbot.run([ "--server", "stop" ])
    end
    
    should "not print when SimpleDaemonize.stop returns false" do
      flexmock(SimpleDaemonize).should_receive(:stop).and_return(false)
      flexmock(Testbot).should_receive(:puts).never
      Testbot.run([ "--stop", "server" ])
    end
    
    should "return false when there are no args" do
      assert_equal false, Testbot.run([])
    end
    
  end
    
  context "self.parse_args" do

    should 'convert ARGV arguments to a hash' do
      hash = Testbot.parse_args("--connect http://127.0.0.1:2288 --working_dir ~/testbot --ssh_tunnel user@testbot_server".split)
      assert_equal ({ :connect => "http://127.0.0.1:2288", :working_dir => "~/testbot", :ssh_tunnel => "user@testbot_server" }), hash
    end
    
    should "handle just a key without a value" do
      hash = Testbot.parse_args([ "--server" ])
      assert_equal ({ :server => true }), hash
    end
    
  end
  
end