module Testbot::Runner
  class ServerUri
    def self.for(config)
      if config.ssh_tunnel
        "http://127.0.0.1:#{Testbot::SERVER_PORT}"
      else
        if config.server_host.to_s.include?('http')
          "#{config.server_host}:#{Testbot::SERVER_PORT}"
        else
          "http://#{config.server_host}:#{Testbot::SERVER_PORT}"
        end
      end
    end
  end
end
