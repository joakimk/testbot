require File.join(File.dirname(__FILE__), '../lib/new_requester.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class NewRequesterTest < Test::Unit::TestCase
  
  context "self.create_by_config" do

    should 'create a requester from config' do
      flexmock(YAML).should_receive(:load_file).once.with("testbot.yml").
                     and_return({ 'server_uri' => 'http://somewhere:2288', 'server_type' => "rsync", 'server_path' => "user@somewhere:/path", 'ignores' => ".git tmp", 'available_runner_usage' => "50%" })
      flexmock(NewRequester).should_receive(:new).once.with('http://somewhere:2288', 'user@somewhere:/path', 'rsync', '.git tmp', '50%')
      NewRequester.create_by_config("testbot.yml")
    end

  end
   
  context "run_tests" do

    should "should be able to create a build" do
      requester = NewRequester.new("http://192.168.1.100:2288", 'git@somewhere', 'git', '', '60%')
      flexmock(requester).should_receive(:find_tests).with(:rspec, 'spec').once.and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      flexmock(HTTParty).should_receive(:post).once.with("http://192.168.1.100:2288/builds",
                                        :body => { :type => "rspec",
                                                   :root => "git@somewhere",
                                                   :server_type => "git",
                                                   :available_runner_usage => "60%",
                                                   :files => "spec/models/house_spec.rb" +
                                                             " spec_models/car_spec.rb" })
          
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, 'results' => '' })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)
      
      assert_equal true, requester.run_tests(:rspec, 'spec')
    end

    should "keep calling the server for results until done" do
      requester = NewRequester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')

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
      requester = NewRequester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')

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
      requester = NewRequester.new("http://192.168.1.100:2288", 'user@somewhere:/path', 'rsync', '.git tmp')

      flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')      
      flexmock(requester).should_receive(:sleep).once
      flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "" })
      
      flexmock(requester).should_receive('system').with("rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh --exclude='.git' --exclude='tmp' . user@somewhere:/path")
      
      requester.run_tests(:rspec, 'spec')
    end
    
    should "return false if there 'failure' is part of the results" do
      requester = NewRequester.new("http://192.168.1.100:2288", 'user@somewhere:/path', 'git')

      flexmock(requester).should_receive(:find_tests).and_return([])
      
      flexmock(HTTParty).should_receive(:post).and_return('5')
      flexmock(requester).should_receive(:sleep).once
       flexmock(requester).should_receive(:puts).once
      flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
                  :format => :json).and_return({ "done" => true, "results" => "... failure ..." })
      
      assert_equal false, requester.run_tests(:rspec, 'spec')
    end
    
    should "return false if there 'error' is part of the results" do
      requester = NewRequester.new("http://192.168.1.100:2288", 'user@somewhere:/path', 'git')

       flexmock(requester).should_receive(:find_tests).and_return([])

       flexmock(HTTParty).should_receive(:post).and_return('5')      
       flexmock(requester).should_receive(:sleep).once
       flexmock(requester).should_receive(:puts).once
       flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:2288/builds/5",
                   :format => :json).and_return({ "done" => true, "results" => "... error ..." })

       assert_equal false, requester.run_tests(:rspec, 'spec')
    end

  end

end
