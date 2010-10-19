require File.join(File.dirname(__FILE__), '../lib/requester.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

def requester_with_result(results)
  requester = Requester.new("http://192.168.1.100:2288", 'user@somewhere:/path', 'git')

  flexmock(requester).should_receive(:find_tests).and_return([])
  flexmock(HTTParty).should_receive(:post).and_return('5')
  flexmock(requester).should_receive(:sleep).once
  flexmock(requester).should_receive(:puts).once
  flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
              :format => :json).and_return({ "done" => true, "results" => results })
  requester
end
  
def build_with_result(results)
  requester_with_result(results).run_tests(:rspec, 'spec')
end


class RequesterTest < Test::Unit::TestCase
  
  context "self.create_by_config" do

    should 'create a requester from config' do
      flexmock(YAML).should_receive(:load_file).once.with("testbot.yml").
                     and_return({ 'server_uri' => 'http://somewhere:2288', 'server_type' => "rsync", 'server_path' => "user@somewhere:/path", 'ignores' => ".git tmp", 'available_runner_usage' => "50%" })
      flexmock(Requester).should_receive(:new).once.with('http://somewhere:2288', 'user@somewhere:/path', 'rsync', '.git tmp', '50%')
      Requester.create_by_config("testbot.yml")
    end

  end
   
  context "run_tests" do

    should "should be able to create a build" do
      flexmock(Mac).should_receive(:addr).and_return('aa:aa:aa:aa:aa:aa')
      requester = Requester.new("http://192.168.1.100:2288", 'git@somewhere', 'git', '', '60%')
      flexmock(requester).should_receive(:find_tests).with(:rspec, 'spec').once.and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      flexmock(HTTParty).should_receive(:post).once.with("http://192.168.1.100:2288/builds",
                                        :body => { :type => "rspec",
                                                   :root => "git@somewhere",
                                                   :server_type => "git",
                                                   :available_runner_usage => "60%",
                                                   :requester_mac => 'aa:aa:aa:aa:aa:aa',
                                                   :files => "spec/models/house_spec.rb" +
                                                             " spec_models/car_spec.rb" })
          
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, 'results' => '' })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)
      
      assert_equal true, requester.run_tests(:rspec, 'spec')
    end

    should "keep calling the server for results until done" do
      requester = Requester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => false, "results" => "job 2 done: ...." },
                                               { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })
      
      flexmock(requester).should_receive(:sleep).times(2).with(1)
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....")
      flexmock(requester).should_receive(:puts).once.with("job 1 done: ....")

      requester.run_tests(:rspec, 'spec')
    end
    
    should "not print empty lines when there is no result" do
      requester = Requester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => false, "results" => "" },
                                               { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

      flexmock(requester).should_receive(:sleep).times(2).with(1)
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
      
      requester.run_tests(:rspec, 'spec')
    end
    
    should "prepare and sync the files to the server when the server_type is rsync" do
      requester = Requester.new("http://192.168.1.100:2288", 'user@somewhere:/path', 'rsync', '.git tmp')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')      
      flexmock(requester).should_receive(:sleep).once
      flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "" })
      
      flexmock(requester).should_receive('system').with("rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh --exclude='.git' --exclude='tmp' . user@somewhere:/path")
      
      requester.run_tests(:rspec, 'spec')
    end
    
    should "just try again if the request encounters an error while running" do
      requester = Requester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(1).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_raise('some connection error')
      flexmock(HTTParty).should_receive(:get).times(1).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

      flexmock(requester).should_receive(:sleep).times(2).with(1)
      flexmock(requester).should_receive(:puts).once.with("Failed to get status: some connection error")
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....") 

      requester.run_tests(:rspec, 'spec')      
    end
    
  end
  
  context "result_lines" do
    
    should "return all lines with results in them" do
      results = "one\ntwo..\n... 0 failures\nthree"
      requester = requester_with_result(results)
      requester.run_tests(:rspec, 'spec')
      assert_equal [ '... 0 failures' ], requester.result_lines
    end
    
  end
  
  context "failure detection" do
    
    should "not fail if the word error or failure is in the text" do
      assert_equal true, build_with_result('... failure ...')
      assert_equal true, build_with_result('... error ...')
    end

    should "fail with single failed" do
      assert_equal false, build_with_result("10 tests, 20 assertions, 0 failures, 0 errors\n10 tests, 20 assertions, 1 failure, 0 errors")
    end

    should "fail with single error" do
      assert_equal false, build_with_result("10 tests, 20 assertions, 0 failures, 1 errors\n10 tests, 20 assertions, 0 failures, 0 errors")
    end

    should "fail with failed and error" do
      assert_equal false, build_with_result("10 tests, 20 assertions, 0 failures, 1 errors\n10 tests, 20 assertions, 1 failures, 1 errors")
    end

    should "fail with multiple failed tests" do
      assert_equal false, build_with_result("10 tests, 20 assertions, 2 failures, 0 errors\n10 tests, 1 assertion, 1 failures, 0 errors")
    end

    should "not fail with successful tests" do
     assert_equal true, build_with_result("10 tests, 20 assertions, 0 failures, 0 errors\n10 tests, 20 assertions, 0 failures, 0 errors")
    end

    should "fail with 10 failures" do
      assert_equal false, build_with_result("10 tests, 20 assertions, 10 failures, 0 errors\n10 tests, 20 assertions, 0 failures, 0 errors")
    end
    
    should "fail with cucumber failure messages" do
      assert_equal false, build_with_result("721 steps (4 failed, 4 skipped, 713 passed)")
    end
    
  end

end
