require 'rubygems'
require 'net/ssh'

class SSHTunnel
  
  def initialize(host, user)
    @host, @user = host, user
  end
  
  def open
    Thread.new do
      Net::SSH.start(@host, @user) do |ssh|
        ssh.forward.local(2288, 'localhost', 2288)
        ssh.loop { @up = true }
      end
    end
    
    while true
      break if @up
    end
  end
  
end
