require File.join(File.dirname(__FILE__), '../lib/new_requester.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class NewRequesterTest < Test::Unit::TestCase
    
    # server_uri: http://192.168.1.100:2288
    # server_path: staging.auktionskompaniet.com:/tmp/testbot/!!USERNAME!!
    # ignores: config/database.yml files/* public/pressbilder/* public/uploaded_images/* public/article_images/* TODO.txt *.war .git/* log/* tmp/war/* public/pdf*
    # local_test_database: auktion_test
    # 
   
  context "self.create_by_config" do

    should 'configure the server uri' do
      flexmock(YAML).should_receive(:load_file).once.with("testbot.yml").
                     and_return({ 'server_uri' => 'http://somewhere:2288', 'server_type' => "git", 'server_path' => "git@somewhere" })
      flexmock(NewRequester).should_receive(:new).once.with('http://somewhere:2288', 'git@somewhere', 'git')
      NewRequester.create_by_config("testbot.yml")
    end

  end
   
  context "run_tests" do

    should "should be able to create a build" do
      requester = NewRequester.new("http://192.168.1.100:2288", 'git@somewhere', 'git')
      flexmock(requester).should_receive(:find_tests).with(:rspec, 'spec').once.and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
      flexmock(HTTParty).should_receive(:post).once.with("http://192.168.1.100:2288/builds",
                                        :body => { :type => "rspec",
                                                   :root => "git@somewhere",
                                                   :server_type => "git",
                                                   :files => "spec/models/house_spec.rb" +
                                                             " spec_models/car_spec.rb" })
          
      flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, 'results' => '' })
      flexmock(requester).should_receive(:sleep)
      flexmock(requester).should_receive(:puts)
      
      requester.run_tests(:rspec, 'spec')
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
  end

end
