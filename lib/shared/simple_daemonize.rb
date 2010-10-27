class SimpleDeamonize
  
  def self.start(cmd, pid_path)    
    pid = fork { 
      STDOUT.reopen "/dev/null"
      exec(cmd)
    }
    
    File.open(pid_path, 'w') { |file| file.write(pid) }
    pid
  end
  
  def self.stop(pid_path)
    return unless File.exists?(pid_path)
    system "kill #{File.read(pid_path)} &> /dev/null"
    system "rm #{pid_path} &> /dev/null"
  end
  
end
