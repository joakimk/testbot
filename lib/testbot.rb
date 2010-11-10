require File.join(File.dirname(__FILE__), '/shared/simple_daemonize')
require File.join(File.dirname(__FILE__), '/adapters/adapter')
require 'fileutils'

class Testbot
  
  VERSION = "0.2.4"
  SERVER_PID="/tmp/testbot_server.pid"
  RUNNER_PID="/tmp/testbot_runner.pid"
  DEFAULT_WORKING_DIR="/tmp/testbot"
  DEFAULT_SERVER_PATH="/tmp/testbot/#{ENV['USER']}"
  SERVER_PORT = ENV['INTEGRATION_TEST'] ? 22880 : 2288
  
  def self.run(argv)
    return false if argv == []
    opts = parse_args(argv)

    if opts[:help]
      return false
    elsif opts[:version]
      puts "Testbot #{VERSION}"
    elsif [ true, 'run', 'start' ].include?(opts[:server])
      start_server(opts[:server])
    elsif opts[:server] == 'stop'
      stop('server', SERVER_PID)
    elsif [ true, 'run', 'start' ].include?(opts[:runner])
      require File.join(File.dirname(__FILE__), '/runner')
      return false unless valid_runner_opts?(opts)
      start_runner(opts)
    elsif opts[:runner] == 'stop'
      stop('runner', RUNNER_PID)
    elsif adapter = Adapter.all.find { |adapter| opts[adapter.type.to_sym] }
      require File.join(File.dirname(__FILE__), '/requester')
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
    stop('runner', RUNNER_PID)
    
    proc = lambda {
      working_dir = opts[:working_dir] || DEFAULT_WORKING_DIR
      FileUtils.mkdir_p(working_dir)
      Dir.chdir(working_dir)
      runner = Runner.new(:server_uri => "http://#{opts[:connect]}:#{SERVER_PORT}",
                          :automatic_updates => false, :max_instances => opts[:cpus],
                          :ssh_tunnel => opts[:ssh_tunnel])
      runner.run!
    }
    
    if opts[:runner] == 'run'
      proc.call
    else
      pid = SimpleDaemonize.start(proc, RUNNER_PID)
      puts "Testbot runner started (pid: #{pid})"
    end
  end
  
  def self.start_server(type)
    stop('server', SERVER_PID)
    
    if type == 'run'
      require File.join(File.dirname(__FILE__), '/server')
      Sinatra::Application.run! :environment => "production"
    else
      pid = SimpleDaemonize.start(lambda {
        ENV['DISABLE_LOGGING'] = "true"
        require File.join(File.dirname(__FILE__), '/server')
        Sinatra::Application.run! :environment => "production"
      }, SERVER_PID)
      puts "Testbot server started (pid: #{pid})"
    end
  end
  
  def self.stop(name, pid)
    puts "Testbot #{name} stopped" if SimpleDaemonize.stop(pid)
  end
  
  def self.start_requester(opts, adapter)
    requester = Requester.new(:server_uri => "http://#{opts[:connect]}:#{SERVER_PORT}", :server_type => 'rsync', :server_path => (opts[:server_path] || DEFAULT_SERVER_PATH), :ignores => opts[:ignores].to_s, :available_runner_usage => "100%", :project => "project", :ssh_tunnel => opts[:ssh_tunnel])
    requester.run_tests(adapter, adapter.base_path)
  end
  
  def self.valid_runner_opts?(opts)
    opts[:connect].is_a?(String)
  end
  
  def self.lib_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  end
  
end
