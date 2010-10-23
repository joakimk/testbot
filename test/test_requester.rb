require File.join(File.dirname(__FILE__), '../lib/requester.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

def requester_with_result(results)
  requester = Requester.new(:server_uri => "http://192.168.1.100:2288", :server_path => 'git@somewhere', :server_type => 'git')

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
                     and_return({ :server_uri => 'http://somewhere:2288', :server_type => 'rsync', :server_path => 'user@somewhere:/path', :ignores => ".git tmp", :available_runner_usage => '50%', :ssh_tunnel => 'user@server' })
      flexmock(Requester).should_receive(:new).once.with({ :server_uri => 'http://somewhere:2288', :server_type => 'rsync', :server_path => 'user@somewhere:/path', :ignores => '.git tmp', :available_runner_usage => '50%', :ssh_tunnel => 'user@server' })
      Requester.create_by_config("testbot.yml")
    end
    
  end
   
  context "run_tests" do

    should "should be able to create a build" do
      flexmock(Mac).should_receive(:addr).and_return('aa:aa:aa:aa:aa:aa')
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288", :server_path => 'git@somewhere', :server_type => 'git', :available_runner_usage => '60%', :project => 'things')
      flexmock(requester).should_receive(:find_tests).with(RSpecAdapter, 'spec').once.and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      flexmock(HTTParty).should_receive(:post).once.with("http://192.168.1.100:2288/builds",
                                        :body => { :type => "rspec",
                                                   :root => "git@somewhere",
                                                   :project => "things",
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
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288")

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
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288")

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => false, "results" => "" },
                                               { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

      flexmock(requester).should_receive(:sleep).times(2).with(1)
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
      
      requester.run_tests(:rspec, 'spec')
    end
    
    should "sync the files to the server when the server_type is rsync" do
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288", :server_path => 'user@somewhere:/path', :server_type => 'rsync', :ignores => '.git tmp')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')      
      flexmock(requester).should_receive(:sleep).once
      flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "" })
      
      flexmock(requester).should_receive('system').with("rsync -az --delete -e ssh --exclude='.git' --exclude='tmp' . user@somewhere:/path")
      
      requester.run_tests(:rspec, 'spec')
    end
    
    should "just try again if the request encounters an error while running and print on the fith time" do
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288")

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(5).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_raise('some connection error')
      flexmock(HTTParty).should_receive(:get).times(1).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

      flexmock(requester).should_receive(:sleep).times(6).with(1)
      flexmock(requester).should_receive(:puts).once.with("Failed to get status: some connection error")
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....") 

      requester.run_tests(:rspec, 'spec')      
    end
    
    should "just try again if the status returns as nil" do
      requester = Requester.new(:server_uri => "http://192.168.1.100:2288")

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
            
      flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return(nil,
                                               { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })
      
      flexmock(requester).should_receive(:sleep).times(2).with(1)
      flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")

      requester.run_tests(:rspec, 'spec')      
    end
    
    should "use SSHTunnel when specified (with a port that does not collide with the runner)" do
      requester = Requester.new(:ssh_tunnel => 'user@server')

      flexmock(SSHTunnel).should_receive(:new).once.with("server", "user", 2299).and_return(ssh_tunnel = Object.new)
      flexmock(ssh_tunnel).should_receive(:open).once

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb' ])
      flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2299/builds", any).and_return('5')
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)

      requester.run_tests(:rspec, 'spec')      
    end
    
    should "use another port for cucumber to be able to run at the same time as rspec" do
      requester = Requester.new(:ssh_tunnel => 'user@server')

      flexmock(SSHTunnel).should_receive(:new).once.with("server", "user", 2230).and_return(ssh_tunnel = Object.new)
      flexmock(ssh_tunnel).should_receive(:open).once

      flexmock(requester).should_receive(:find_tests).and_return([ 'features/some.feature' ])
      flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2230/builds", any).and_return('5')
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)

      requester.run_tests(:cucumber, 'features')
    end
    
    should "use another port for Test::Unit" do
      requester = Requester.new(:ssh_tunnel => 'user@server')

      flexmock(SSHTunnel).should_receive(:new).once.with("server", "user", 2231).and_return(ssh_tunnel = Object.new)
      flexmock(ssh_tunnel).should_receive(:open).once

      flexmock(requester).should_receive(:find_tests).and_return([ 'test/some_test.rb' ])
      flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2231/builds", any).and_return('5')
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)

      requester.run_tests(:test, 'test')
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
