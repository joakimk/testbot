require File.expand_path(File.join(File.dirname(__FILE__), '../lib/testbot')) unless defined?(Testbot)
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'
require File.join(File.dirname(__FILE__), '../lib/requester')
require File.join(File.dirname(__FILE__), '../lib/server')

module Testbot

  module TestHelpers

    def requester_attributes
      { :server_host => "192.168.0.100",
        :rsync_path => nil,
        :rsync_ignores => '', :server_user => nil, :available_runner_usage => nil,
        :project => nil, :ssh_tunnel => nil }
    end  
  
  end

  class CLITest < Test::Unit::TestCase
    
    include TestHelpers
    
    context "self.run" do

      context "with no args" do
        should "return false" do
          assert_equal false, CLI.run([])
        end   
      end
    
      context "with --help" do
        should "return false" do
          assert_equal false, CLI.run([ '--help' ])
        end      
      end
    
      context "with --version" do
        should "print version and return true" do
          flexmock(CLI).should_receive(:puts).once.with("Testbot #{Testbot.version}")
          assert_equal true, CLI.run([ '--version' ])
        end
      end
        
      context "with --server" do
        should "start a server" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).once.with(any, Testbot::SERVER_PID, "testbot (server)")
          flexmock(CLI).should_receive(:puts).once.with("Testbot server started (pid: #{Process.pid})")
          assert_equal true, CLI.run([ "--server" ])
        end
      
        should "start a server when start is passed" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).once
          flexmock(CLI).should_receive(:puts)
          assert_equal true, CLI.run([ "--server", "start" ])
        end
    
        should "stop a server when stop is passed" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID).and_return(true)
          flexmock(CLI).should_receive(:puts).once.with("Testbot server stopped")
          assert_equal true, CLI.run([ "--server", "stop" ])
        end
    
        should "not print when SimpleDaemonize.stop returns false" do
          flexmock(SimpleDaemonize).should_receive(:stop).and_return(false)
          flexmock(CLI).should_receive(:puts).never
          CLI.run([ "--stop", "server" ])
        end
      
        should "start it in the foreground with run" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::SERVER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).never
          flexmock(Sinatra::Application).should_receive(:run!).once.with(:environment => "production")
          assert_equal true, CLI.run([ "--server", 'run' ])
        end
      end
  
      context "with --runner" do
        should "start a runner" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).once.with(any, Testbot::RUNNER_PID, "testbot (runner)")
          flexmock(CLI).should_receive(:puts).once.with("Testbot runner started (pid: #{Process.pid})")
          assert_equal true, CLI.run([ "--runner", "--connect", "192.168.0.100", "--working_dir", "/tmp/testbot" ])
        end
      
        should "start a runner when start is passed" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).once
          flexmock(CLI).should_receive(:puts)
          assert_equal true, CLI.run([ "--runner", "start", "--connect", "192.168.0.100" ])
        end
      
        should "stop a runner when stop is passed" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID).and_return(true)
          flexmock(CLI).should_receive(:puts).once.with("Testbot runner stopped")
          assert_equal true, CLI.run([ "--runner", "stop" ])
        end
      
        should "return false without connect" do
          assert_equal false, CLI.run([ "--runner", "--connect" ])
          assert_equal false, CLI.run([ "--runner" ])
        end
      
        should "start it in the foreground with run" do
          flexmock(SimpleDaemonize).should_receive(:stop).once.with(Testbot::RUNNER_PID)
          flexmock(SimpleDaemonize).should_receive(:start).never
          flexmock(Runner).should_receive(:new).once.and_return(mock = Object.new)
          flexmock(mock).should_receive(:run!).once
          assert_equal true, CLI.run([ "--runner", 'run', '--connect', '192.168.0.100' ])
        end
      end
    
      Adapter.all.each do |adapter|
        context "with --#{adapter.type}" do
          should "start a #{adapter.name} requester and return true" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes).and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests).once.with(adapter, adapter.base_path)
            assert_equal true, CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100" ])
          end
        
          should "accept a custom rsync_path" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes.merge({ :rsync_path => "/somewhere/else" })).
                                and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests)
            CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--rsync_path', '/somewhere/else' ])
          end
        
          should "accept rsync_ignores" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes.merge({ :rsync_ignores => "tmp log" })).
                                and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests)
            CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--rsync_ignores', 'tmp', 'log' ])
          end
        
          should "accept ssh tunnel" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes.merge({ :ssh_tunnel => true })).
                                and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests)
            CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--ssh_tunnel' ])
          end
          
          should "accept a custom user" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes.merge({ :server_user => "cruise" })).
                                and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests)
            CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--user', 'cruise' ])
          end
          
          should "accept a custom project name" do
            flexmock(Requester).should_receive(:new).once.
                                with(requester_attributes.merge({ :project => "rspec" })).
                                and_return(mock = Object.new)
            flexmock(mock).should_receive(:run_tests)
            CLI.run([ "--#{adapter.type}", "--connect", "192.168.0.100", '--project', 'rspec' ])
          end
        end
      end
    end
    
    context "self.parse_args" do

      should 'convert ARGV arguments to a hash' do
        hash = CLI.parse_args("--runner --connect http://127.0.0.1:#{Testbot::SERVER_PORT} --working_dir ~/testbot --ssh_tunnel user@testbot_server".split)
        assert_equal ({ :runner => true, :connect => "http://127.0.0.1:#{Testbot::SERVER_PORT}", :working_dir => "~/testbot", :ssh_tunnel => "user@testbot_server" }), hash
      end
    
      should "handle just a key without a value" do
        hash = CLI.parse_args([ "--server" ])
        assert_equal ({ :server => true }), hash
      end
    
    end
  
  end
  
end
