require 'rubygems'
require 'net/ssh'

class SSHTunnel
  def initialize(host, user, local_port = 2288)
    @host, @user, @local_port = host, user, local_port
  end

  def open
    connect

    start_time = Time.now
    while true
      break if @up
      sleep 0.5

      if Time.now - start_time > 5
        puts "SSH connection failed, trying again..."
        start_time = Time.now
        connect
      end
    end
  end

  def connect
    @thread.kill if @thread
    @thread = Thread.new do
      Net::SSH.start(@host, @user, { :timeout => 1 }) do |ssh|
        ssh.forward.local(@local_port, 'localhost', Testbot::SERVER_PORT)
        ssh.loop {  @up = true }
      end
    end
  end
end
