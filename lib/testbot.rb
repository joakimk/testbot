require File.join(File.dirname(__FILE__), '/shared/simple_daemonize')

class Testbot
  
  VERSION = "0.2.x"
  SERVER_PID="/tmp/testbot_server.pid"
  RUNNER_PID="/tmp/testbot_runner.pid"
  
  def self.run(argv)
    return false if argv == []
    opts = parse_args(argv)

    if opts[:server] == true
      start_server
    elsif opts[:server] == 'stop'
      stop('server', SERVER_PID)
    elsif opts[:runner] == true
      return false unless valid_runner_opts?(opts)
      start_runner(opts)
    elsif opts[:runner] == 'stop'
      stop('runner', RUNNER_PID)
    end
    
    true
  end
  
  def self.parse_args(argv)
    last_setter = nil
    hash = {}
    argv.each_with_index do |arg, i|
      if arg.include?('--')
        last_setter = arg.split('--').last.to_sym
        hash[last_setter] = true if (i == argv.size - 1) || argv[i+1].include?('--')
      else
        hash[last_setter] = arg
      end
    end
    hash
  end
  
  def self.start_runner(opts)
    stop('runner', RUNNER_PID)
    pid = SimpleDaemonize.start(lambda {
      require File.join(File.dirname(__FILE__), '/runner')
      Dir.chdir(opts[:working_dir])
      port = ENV['INTEGRATION_TEST'] ? 22880 : 2288
      runner = Runner.new(:server_uri => "http://#{opts[:connect]}:#{port}",
                          :automatic_updates => false, :max_instances => 1)
     runner.run!
   }, RUNNER_PID)
    puts "Testbot runner started (pid: #{pid})"
  end
  
  def self.start_server
    stop('server', SERVER_PID)
    pid = SimpleDaemonize.start(lambda {
      ENV['DISABLE_LOGGING'] = "true"
      require File.join(File.dirname(__FILE__), '/server')
      Sinatra::Application.run! :environment => "production"
    }, SERVER_PID)
    puts "Testbot server started (pid: #{pid})"
  end
  
  def self.stop(name, pid)
    puts "Testbot #{name} stopped" if SimpleDaemonize.stop(pid)
  end
  
  def self.valid_runner_opts?(opts)
    opts[:connect].is_a?(String) && opts[:working_dir].is_a?(String)
  end
  
  def self.lib_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  end
  
end
