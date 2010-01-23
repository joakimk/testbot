require 'test/unit'
require 'fileutils'

class IntegrationTest < Test::Unit::TestCase

  # This is slow, and Test:Unit does not have "before :all" method, so I'm using a single testcase for multiple tests
  def test_integration
    system "mkdir tmp; cp -rf test/fixtures/local tmp/local"
    system "mkdir tmp/runner; cd tmp/runner; ../../bin/testbot_runner start"
    system "mkdir tmp/server; bin/testbot_server start"
    sleep 0.5
    result = `cd tmp/local; INTEGRATION_TEST=true ruby ../../lib/requester.rb`
    
    assert result.include?("prepare got called\n" + 'script/spec got called with ["-O", "spec/spec.opts", "spec/models/car_spec.rb", "spec/models/house_spec.rb"]')
    assert !File.exists?("tmp/server/log/test.log")
    assert !File.exists?("tmp/server/tmp/restart.txt")
    assert !File.exists?("tmp/runner/instance0/log/test.log")
    assert !File.exists?("tmp/runner/instance0/tmp/restart.txt")
  end
  
  def teardown
    system "bin/testbot_server stop"
    system "bin/testbot_runner stop"
    FileUtils.rm_rf "tmp"    
  end

end
