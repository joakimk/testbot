require 'rubygems'
require 'daemons'

class Testbot
  VERSION = "0.2.x"
  
  def self.run(argv)
    if parse_args(argv)[:server]
      start_server
      true
    else
      false
    end
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
    lib_dir = File.expand_path(File.join(File.dirname(__FILE__),'..','lib'))
    Daemons.call do
      Dir.chdir(lib_dir)
      exec "ruby server.rb -e production"
    end
  end
end
