require File.expand_path(File.join(File.dirname(__FILE__), '/simple_daemonize'))
require File.expand_path(File.join(File.dirname(__FILE__), '/adapters/adapter'))
require 'fileutils'

module Testbot
  require 'railtie' if defined?(Rails)

  # Don't forget to update readme and changelog
  def self.version
    version = "0.5.0"
    dev_version_file = File.join(File.dirname(__FILE__), '..', '..', 'DEV_VERSION')
    if File.exists?(dev_version_file)
      version += File.read(dev_version_file)
    end
    version
  end

  if ENV['INTEGRATION_TEST']
    SERVER_PID = "/tmp/integration_test_testbot_server.pid"
    RUNNER_PID = "/tmp/integration_test_testbot_runner.pid"
  else
    SERVER_PID = "/tmp/testbot_server.pid"
    RUNNER_PID = "/tmp/testbot_runner.pid"
  end

  DEFAULT_WORKING_DIR = "/tmp/testbot"
  DEFAULT_SERVER_PATH = "/tmp/testbot/#{ENV['USER']}"
  DEFAULT_USER = "testbot"
  DEFAULT_PROJECT = "project"
  DEFAULT_RUNNER_USAGE = "100%"
  SERVER_PORT = ENV['INTEGRATION_TEST'] ? 22880 : 2288

  class CLI

    def self.run(argv)
      return false if argv == []
      opts = parse_args(argv)

      if opts[:help]
        return false
      elsif opts[:version]
        puts "Testbot #{Testbot.version}"
      elsif [ true, 'run', 'start' ].include?(opts[:server])
        start_server(opts[:server])
      elsif opts[:server] == 'stop'
        stop('server', Testbot::SERVER_PID)
      elsif [ true, 'run', 'start' ].include?(opts[:runner])
        require File.expand_path(File.join(File.dirname(__FILE__), '/../runner/runner'))
        return false unless valid_runner_opts?(opts)
        start_runner(opts)
      elsif opts[:runner] == 'stop'
        stop('runner', Testbot::RUNNER_PID)
      elsif adapter = Adapter.all.find { |adapter| opts[adapter.type.to_sym] }
        require File.expand_path(File.join(File.dirname(__FILE__), '/../requester/requester'))
        start_requester(opts, adapter)
      end

      true
    end

    def self.parse_args(argv)
      last_setter = nil
      hash = {}
      str = ''
      argv.each_with_index do |arg, i|
        if arg.include?('--')
          str = ''
          last_setter = arg.split('--').last.to_sym
          hash[last_setter] = true if (i == argv.size - 1) || argv[i+1].include?('--')
        else
          str += ' ' + arg
          hash[last_setter] = str.strip
        end
      end
      hash
    end

    def self.start_runner(opts)
      stop('runner', Testbot::RUNNER_PID)

      proc = lambda {
        working_dir = opts[:working_dir] || Testbot::DEFAULT_WORKING_DIR
        FileUtils.mkdir_p(working_dir)
        Dir.chdir(working_dir)
        runner = Runner::Runner.new(:server_host => opts[:connect],
                                    :auto_update => opts[:auto_update], :max_instances => opts[:cpus],
                                    :ssh_tunnel => opts[:ssh_tunnel], :server_user => opts[:user],
                                    :max_jruby_instances => opts[:max_jruby_instances],
                                    :dev_gem_root => opts[:dev_gem_root],
                                    :wait_for_updated_gem => opts[:wait_for_updated_gem],
                                    :jruby_opts => opts[:jruby_opts])
        runner.run!
      }

      if opts[:runner] == 'run'
        proc.call
      else
        puts "Testbot runner started (pid: #{Process.pid})"
        SimpleDaemonize.start(proc, Testbot::RUNNER_PID, "testbot (runner)")
      end
    end

    def self.start_server(type)
      stop('server', Testbot::SERVER_PID)
      require File.expand_path(File.join(File.dirname(__FILE__), '/../server/server'))

      if type == 'run'
        Sinatra::Application.run! :environment => "production"
      else
        puts "Testbot server started (pid: #{Process.pid})"
        SimpleDaemonize.start(lambda {
          Sinatra::Application.run! :environment => "production"
        }, Testbot::SERVER_PID, "testbot (server)")
      end
    end

    def self.stop(name, pid)
      puts "Testbot #{name} stopped" if SimpleDaemonize.stop(pid)
    end

    def self.start_requester(opts, adapter)
      requester = Requester::Requester.new(:server_host            => opts[:connect],
                                           :rsync_path             => opts[:rsync_path],
                                           :rsync_ignores          => opts[:rsync_ignores].to_s,
                                           :available_runner_usage => nil,
                                           :project                => opts[:project],
                                           :ssh_tunnel             => opts[:ssh_tunnel], :server_user => opts[:user])
      requester.run_tests(adapter, adapter.base_path)
    end

    def self.valid_runner_opts?(opts)
      opts[:connect].is_a?(String)
    end

    def self.lib_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
    end

  end

end
