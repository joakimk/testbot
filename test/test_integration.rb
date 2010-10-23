require 'rubygems'
require 'test/unit'
require 'fileutils'
require 'shoulda'

class IntegrationTest < Test::Unit::TestCase

  # This is slow, and Test:Unit does not have "before/after :all" method, so I'm using a single testcase for multiple tests
  should "be able to send a build request, have it run and show the results" do
    system "mkdir -p tmp/runner; cp -rf test/fixtures/local tmp/local"
    system "cd tmp/runner; INTEGRATION_TEST=true ../../bin/runner start &>/dev/null"
    system "mkdir tmp/server; INTEGRATION_TEST=true bin/server start &>/dev/null"
    sleep 0.5
    result = `cd tmp/local; INTEGRATION_TEST=true ruby ../../lib/requester.rb`
  
    # Should include the result from script/spec
    #puts result.inspect
    assert result.include?('script/spec got called with ["-O", "spec/spec.opts", "spec/models/house_spec.rb", "spec/models/car_spec.rb"]')
  
    # Should not include ignored files
    assert !File.exists?("tmp/server/log/test.log")
    assert !File.exists?("tmp/server/tmp/restart.txt")
    assert !File.exists?("tmp/runner/instance_rsync/log/test.log")
    assert !File.exists?("tmp/runner/instance_rsync/tmp/restart.txt")
  end
  
  def teardown
    system "bin/server stop &>/dev/null"
    # daemon places the pid in PWD, so we need to be there to close it.
    system "cd tmp/runner; ../../bin/runner stop &>/dev/null"
    FileUtils.rm_rf "tmp"    
  end

end
