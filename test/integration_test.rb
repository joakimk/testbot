require 'test/unit'
require 'fileutils'
require "open3"
include Open3

class IntegrationTest < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf "tmp"
  end

  def test_running_the_requester_will_run_tests_and_print_the_result    
    fork { popen3("mkdir -p tmp/server; ruby server.rb") }
    fork { popen3("mkdir -p tmp/runner; cd tmp/runner; ruby ../../runner.rb") }
    
    sleep 0.5
    result = `cd test/fixtures/local; ruby ../../../requester.rb`
    assert result.include?('script/spec got called with ["-O", "spec/spec.opts", "spec/models/car_spec.rb", "spec/models/house_spec.rb"]')
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
