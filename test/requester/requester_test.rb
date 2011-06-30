require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/requester/requester.rb'))
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

# Probably a bug in flexmock, for 1.9.2
unless defined?(Test::Unit::AssertionFailedError)
  class Test::Unit::AssertionFailedError
  end
end

module Testbot::Requester

  class RequesterTest < Test::Unit::TestCase

    def requester_with_result(results)
      requester = Requester.new(:server_host => "192.168.1.100", :rsync_path => 'user@server:/tmp/somewhere')

      flexmock(requester).should_receive(:find_tests).and_return([])
      flexmock(HTTParty).should_receive(:post).and_return('5')
      flexmock(requester).should_receive(:sleep).once
      flexmock(requester).should_receive(:puts).once
      flexmock(requester).should_receive(:system)
      flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                        :format => :json).and_return({ "done" => true, "results" => results })
                                                        requester
    end

    def build_with_result(results)
      requester_with_result(results).run_tests(RspecAdapter, 'spec')
    end

    def setup
      ENV['USE_JRUBY'] = nil
    end

    def mock_file_sizes
      flexmock(File).should_receive(:stat).and_return(mock = Object.new)
      flexmock(mock).should_receive(:size).and_return(0)
    end

    def fixture_path(local_path)
      File.join(File.dirname(__FILE__), local_path)
    end

    context "self.create_by_config" do

      should 'create a requester from config' do
        requester = Requester.create_by_config(fixture_path("testbot.yml"))
        assert_equal 'hostname', requester.config.server_host
        assert_equal '/path', requester.config.rsync_path
        assert_equal '.git tmp', requester.config.rsync_ignores
        assert_equal 'appname', requester.config.project
        assert_equal false, requester.config.ssh_tunnel
        assert_equal 'user', requester.config.server_user
        assert_equal '50%', requester.config.available_runner_usage
      end

      should 'accept ERB-snippets in testbot.yml' do
        requester = Requester.create_by_config(fixture_path("testbot_with_erb.yml"))
        assert_equal 'dynamic_host', requester.config.server_host
        assert_equal '50%', requester.config.available_runner_usage
      end
    end

    context "initialize" do

      should "use defaults when values are missing" do
        expected = { :server_host            => 'hostname',
          :rsync_path             => Testbot::DEFAULT_SERVER_PATH,
          :project                => Testbot::DEFAULT_PROJECT,
          :server_user            => Testbot::DEFAULT_USER,
          :available_runner_usage => Testbot::DEFAULT_RUNNER_USAGE }

        actual = Requester.new({ "server_host" => 'hostname' }).config 

        assert_equal OpenStruct.new(expected), actual
      end

    end

    context "run_tests" do

      should "should be able to create a build" do
        requester = Requester.new(:server_host => "192.168.1.100", :rsync_path => '/path', :available_runner_usage => '60%', :project => 'things', :server_user => "cruise")
        flexmock(RspecAdapter).should_receive(:test_files).with('spec').once.and_return([ 'spec/models/house_spec.rb', 'spec/models/car_spec.rb' ])

        flexmock(File).should_receive(:stat).once.with("spec/models/house_spec.rb").and_return(mock = Object.new); flexmock(mock).should_receive(:size).and_return(10)
        flexmock(File).should_receive(:stat).once.with("spec/models/car_spec.rb").and_return(mock = Object.new); flexmock(mock).should_receive(:size).and_return(20)

        flexmock(HTTParty).should_receive(:post).once.with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds",
                                                           :body => { :type => "spec",
                                                             :root => "cruise@192.168.1.100:/path",
                                                             :project => "things",
                                                             :available_runner_usage => "60%",
                                                             :files => "spec/models/house_spec.rb" +
                                                             " spec/models/car_spec.rb",
                                                             :sizes => "10 20",
                                                             :jruby => false })

        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, 'results' => '', "success" => true })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)
        flexmock(requester).should_receive(:system)

        assert_equal true, requester.run_tests(RspecAdapter, 'spec')
      end

      should "print the sum of results formatted by the adapter" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return({ "done" => false, "results" => "job 2 done: ...." },
                                                                { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })
                                                              mock_file_sizes

        flexmock(requester).should_receive(:sleep).times(2).with(1)
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....")
        flexmock(requester).should_receive(:puts).once.with("job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\nformatted result")

        flexmock(RspecAdapter).should_receive(:sum_results).with("job 2 done: ....job 1 done: ....").and_return("formatted result")
        requester.run_tests(RspecAdapter, 'spec')        
      end

      should "keep calling the server for results until done" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return({ "done" => false, "results" => "job 2 done: ...." },
                                                                { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })
        mock_file_sizes

        flexmock(requester).should_receive(:sleep).times(2).with(1)
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....")
        flexmock(requester).should_receive(:puts).once.with("job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\n\033[32m0 examples, 0 failures\033[0m")

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "return false if not successful" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                          :format => :json).and_return({ "success" => false, "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

        flexmock(requester).should_receive(:sleep).once.with(1)
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\n\033[32m0 examples, 0 failures\033[0m")
        mock_file_sizes

        assert_equal false, requester.run_tests(RspecAdapter, 'spec')
      end

      should "not print empty lines when there is no result" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return({ "done" => false, "results" => "" },
                                                                { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

        flexmock(requester).should_receive(:sleep).times(2).with(1)
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\n\033[32m0 examples, 0 failures\033[0m")
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "sync the files to the server" do
        requester = Requester.new(:server_host => "192.168.1.100", :rsync_path => '/path', :rsync_ignores => '.git tmp')

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')
        flexmock(requester).should_receive(:sleep).once
        flexmock(requester).should_receive(:puts)
        flexmock(HTTParty).should_receive(:get).once.with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                          :format => :json).and_return({ "done" => true, "results" => "" })

        flexmock(requester).should_receive('system').with("rsync -az --delete -e ssh --exclude='.git' --exclude='tmp' . testbot@192.168.1.100:/path")
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "just try again if the request encounters an error while running and print on the fith time" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(5).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_raise('some connection error')
                                                              flexmock(HTTParty).should_receive(:get).times(1).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                                                                                    :format => :json).and_return({ "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

        flexmock(requester).should_receive(:sleep).times(6).with(1)
        flexmock(requester).should_receive(:puts).once.with("Failed to get status: some connection error")
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\n\033[32m0 examples, 0 failures\033[0m")
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "just try again if the status returns as nil" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return(nil,
                                                                { "done" => true, "results" => "job 2 done: ....job 1 done: ...." })

        flexmock(requester).should_receive(:sleep).times(2).with(1)
        flexmock(requester).should_receive(:puts).once.with("job 2 done: ....job 1 done: ....")
        flexmock(requester).should_receive(:puts).once.with("\n\033[32m0 examples, 0 failures\033[0m")
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "print and error message and return false if an error is returned" do
        requester = Requester.new(:server_host => "192.168.1.100")

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return({ "done" => false, "results" => "" },
                                                                { "error" => "Error message" })

        flexmock(requester).should_receive(:sleep).times(2).with(1)
        flexmock(requester).should_receive(:puts).once.with("Error message")
        mock_file_sizes

        assert !requester.run_tests(RspecAdapter, 'spec')
      end

      should "remove unnessesary output from rspec when told to do so" do
        requester = Requester.new(:server_host => "192.168.1.100", :simple_output => true)

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb', 'spec_models/car_spec.rb' ])
        flexmock(requester).should_receive(:system)

        flexmock(HTTParty).should_receive(:post).and_return('5')

        flexmock(HTTParty).should_receive(:get).times(2).with("http://192.168.1.100:#{Testbot::SERVER_PORT}/builds/5",
                                                              :format => :json).and_return(nil,
                                                                { "done" => true, "results" => "testbot4:\n....\n\nFinished in 84.333 seconds\n\n206 examples, 0 failures, 2 pending; testbot4:\n.F..\n\nFinished in 84.333 seconds\n\n206 examples, 0 failures, 2 pending" })

        flexmock(requester).should_receive(:sleep).times(2).with(1)

        # Imperfect match, includes "." in 84.333, but good enough.
        flexmock(requester).should_receive(:print).once.with("......F...")
        flexmock(requester).should_receive(:puts)
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "use SSHTunnel when specified (with a port that does not collide with the runner)" do
        requester = Requester.new(:ssh_tunnel => true, :server_host => "somewhere")
        flexmock(requester).should_receive(:system)

        flexmock(SSHTunnel).should_receive(:new).once.with("somewhere", "testbot", 2299).and_return(ssh_tunnel = Object.new)
        flexmock(ssh_tunnel).should_receive(:open).once

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb' ])
        flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2299/builds", any).and_return('5')
        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "use another user for rsync and ssh_tunnel when specified" do
        requester = Requester.new(:ssh_tunnel => true, :server_host => "somewhere",
                                  :server_user => "cruise", :rsync_path => "/tmp/testbot/foo")

        flexmock(SSHTunnel).should_receive(:new).once.with("somewhere", "cruise", 2299).and_return(ssh_tunnel = Object.new)
        flexmock(ssh_tunnel).should_receive(:open).once

        flexmock(requester).should_receive(:find_tests).and_return([ 'spec/models/house_spec.rb' ])
        flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2299/builds", any).and_return('5')
        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)

        flexmock(requester).should_receive('system').with("rsync -az --delete -e ssh  . cruise@somewhere:/tmp/testbot/foo")
        mock_file_sizes

        requester.run_tests(RspecAdapter, 'spec')
      end

      should "use another port for cucumber to be able to run at the same time as rspec" do
        requester = Requester.new(:ssh_tunnel => true, :server_host => "somewhere")
        flexmock(requester).should_receive(:system)

        flexmock(SSHTunnel).should_receive(:new).once.with("somewhere", "testbot", 2230).and_return(ssh_tunnel = Object.new)
        flexmock(ssh_tunnel).should_receive(:open).once

        flexmock(requester).should_receive(:find_tests).and_return([ 'features/some.feature' ])
        flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2230/builds", any).and_return('5')
        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)
        mock_file_sizes

        requester.run_tests(CucumberAdapter, 'features')
      end

      should "use another port for Test::Unit" do
        requester = Requester.new(:ssh_tunnel => true, :server_host => "somewhere")
        flexmock(requester).should_receive(:system)

        flexmock(SSHTunnel).should_receive(:new).once.with("somewhere", "testbot", 2231).and_return(ssh_tunnel = Object.new)
        flexmock(ssh_tunnel).should_receive(:open).once

        flexmock(requester).should_receive(:find_tests).and_return([ 'test/some_test.rb' ])
        flexmock(HTTParty).should_receive(:post).with("http://127.0.0.1:2231/builds", any).and_return('5')
        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)
        mock_file_sizes

        requester.run_tests(TestUnitAdapter, 'test')
      end

      should "request a run with jruby if USE_JRUBY is set" do
        ENV['USE_JRUBY'] = "true"
        requester = Requester.new
        flexmock(requester).should_receive(:system)

        # This is quite ugly. I want something like hash_including instead...
        other_args = { :type=>"test", :available_runner_usage=>"100%",
          :root=>"testbot@:/tmp/testbot/#{ENV['USER']}", :files=>"test/some_test.rb",
          :sizes=>"0", :project=>"project" }

        flexmock(TestUnitAdapter).should_receive(:test_files).and_return([ 'test/some_test.rb' ])
        flexmock(HTTParty).should_receive(:post).with(any, :body => other_args.merge({ :jruby => true })).and_return('5')
        flexmock(HTTParty).should_receive(:get).and_return({ "done" => true, "results" => "job 1 done: ...." })
        flexmock(requester).should_receive(:sleep)
        flexmock(requester).should_receive(:puts)
        mock_file_sizes

        requester.run_tests(TestUnitAdapter, 'test')
      end

    end

  end

end
