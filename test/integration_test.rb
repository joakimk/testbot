require 'test/unit'
require 'fileutils'
require "open3"
include Open3

class IntegrationTest < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf "tmp"
  end

  # This is slow, and Test:Unit does not have "before :all" method, so I'm using a single testcase for multiple tests
  def test_integration
    system "mkdir tmp; cp -rf test/fixtures/local tmp/local"
    fork { popen3("mkdir tmp/server; ruby server.rb") }
    fork { popen3("mkdir tmp/runner; cd tmp/runner; ruby ../../runner.rb") }
    sleep 0.5
    result = `cd tmp/local; INTEGRATION_TEST=true ruby ../../requester.rb`
    
    assert result.include?("prepare got called\n" + 'script/spec got called with ["-O", "spec/spec.opts", "spec/models/car_spec.rb", "spec/models/house_spec.rb"]')
    assert !File.exists?("tmp/server/log/test.log")
    assert !File.exists?("tmp/server/tmp/restart.txt")
    assert !File.exists?("tmp/runner/project/log/test.log")
    assert !File.exists?("tmp/runner/project/tmp/restart.txt")
  end
  
  def teardown
    find_and_kill_process("../../runner.rb")
    find_and_kill_process("server.rb")
    FileUtils.rm_rf "tmp"    
  end
  
  def find_and_kill_process(file)
    # TODO: Very ugly, but works. How do you kill a non-ruby sub process anyways?
    pid = `ps ax | grep "ruby #{file}"`.split("\n").find { |line| line.split[4] == 'ruby' }.split.first
    system "kill #{pid}"    
  end
  
end
