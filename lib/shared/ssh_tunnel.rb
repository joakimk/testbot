require 'rubygems'
require 'net/ssh'

class SSHTunnel
  
  def initialize(host, user, local_port = 2288)
    @host, @user, @local_port = host, user, local_port
  end
  
  def open
    Thread.new do
      Net::SSH.start(@host, @user) do |ssh|
        ssh.forward.local(@local_port, 'localhost', 2288)
        ssh.loop { @up = true }
      end
    end
    
    while true
      break if @up
      sleep 0.5
    end
  end
  
end
