require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/shared/testbot.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/runner/server_uri.rb'))
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class ServerUriTest < Test::Unit::TestCase
  
  should "construct a http url" do
    config = flexmock(:ssh_tunnel => false, :server_host => "example.com")
    server_uri = Testbot::Runner::ServerUri.for(config)
    assert_equal 'http://example.com:2288', server_uri
  end

  should "return a local url when using ssh tunnel" do
    config = flexmock(:ssh_tunnel => true, :server_host => "example.com")
    server_uri = Testbot::Runner::ServerUri.for(config)
    assert_equal 'http://127.0.0.1:2288', server_uri
  end

  should "return the server_host as-is if it includes http" do
    config = flexmock(:ssh_tunnel => false, :server_host => "https://example.com")
    server_uri = Testbot::Runner::ServerUri.for(config)
    assert_equal 'https://example.com:2288', server_uri
  end

end
