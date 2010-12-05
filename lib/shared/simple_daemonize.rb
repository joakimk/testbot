require 'rubygems'
require 'daemons'

class SimpleDaemonize
  
  def self.start(proc, pid_path, app_name)    
    working_dir = Dir.pwd

    group = Daemons::ApplicationGroup.new(app_name)
    group.new_application(:mode => :none).start

    File.open(pid_path, 'w') { |file| file.write(Process.pid) }
    Dir.chdir(working_dir)
    proc.call
  end
  
  def self.stop(pid_path)
    return unless File.exists?(pid_path)
    pid = File.read(pid_path)

    system "kill -9 #{pid} &> /dev/null"
    system "rm #{pid_path} &> /dev/null"
  end
  
end
