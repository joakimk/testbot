require File.join(File.dirname(__FILE__), '/shared/simple_daemonize')

class Testbot
  
  VERSION = "0.2.x"
  SERVER_PID="/tmp/testbot_server.pid"
  
  def self.run(argv)
    return false if argv == []
    opts = parse_args(argv)

    if opts[:server] == true
      start_server
    elsif opts[:server] == 'stop'
      stop_server
    end
    
    true
  end
  
  def self.parse_args(argv)
    last_setter = nil
    hash = {}
    argv.each_with_index do |arg, i|
      if arg.include?('--')
        last_setter = arg.split('--').last.to_sym
        hash[last_setter] = true if (i == argv.size - 1)
      else
        hash[last_setter] = arg
      end
    end
    hash
  end
  
  def self.start_server
    stop_server
    pid = SimpleDaemonize.start("ruby #{lib_path}/server.rb -e production", SERVER_PID)
    puts "Testbot server started (pid: #{pid})"
  end
  
  def self.stop_server
    puts "Testbot server stopped" if SimpleDaemonize.stop(SERVER_PID)
  end
  
  def self.lib_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  end
  
end
