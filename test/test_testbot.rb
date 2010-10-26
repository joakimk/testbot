require File.join(File.dirname(__FILE__), '../lib/testbot.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class TestbotTest < Test::Unit::TestCase
    
  context "self.run" do
    
    should "start a server and return true when --server is passed" do
      flexmock(Testbot).should_receive(:start_server).once
      assert_equal true, Testbot.run([ "--server" ])
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