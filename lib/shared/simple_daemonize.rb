class SimpleDaemonize
  
  def self.start(proc, pid_path)    
    pid = fork { 
      STDOUT.reopen "/dev/null"
      proc.call
    }
   
    File.open(pid_path, 'w') { |file| file.write(pid) }
    pid
  end
  
  def self.stop(pid_path)
    return unless File.exists?(pid_path)
    pid = File.read(pid_path)

    system "kill #{pid} &> /dev/null"
    system "rm #{pid_path} &> /dev/null"
  end
  
end
