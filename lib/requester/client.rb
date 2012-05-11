module Testbot::Requester
  class Client
    def initialize(config, adapter, requester)
      @config = config
      @adapter = adapter
      @requester = requester
    end
      
    def request_run(dir)
      if config.ssh_tunnel
        log "Setting up ssh tunnel" do
          SSHTunnel.new(config.server_host, config.server_user, adapter.requester_port).open
        end
        @server_uri = "http://127.0.0.1:#{adapter.requester_port}"
      else
        @server_uri = "http://#{config.server_host}:#{Testbot::SERVER_PORT}"
      end

      log "Syncing files" do
        rsync_ignores = config.rsync_ignores.to_s.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
        # todo: exit when this fails
        requester.send(:system, "rsync -az --delete --delete-excluded -e ssh #{rsync_ignores} . #{rsync_uri}")
      end

      files = adapter.test_files(dir) 
      sizes = adapter.get_sizes(files)

      success = false
      log "Requesting run" do
        response = HTTParty.post("#{@server_uri}/builds", :body => { :root => root,
                                 :type => adapter.type.to_s,
                                 :project => config.project,
                                 :available_runner_usage => config.available_runner_usage,
                                 :files => files.join(' '),
                                 :sizes => sizes.join(' '),
                                 :jruby => jruby? }).response


        if response.code == "503"
          @error_type = :no_runners_available
          return false
        elsif response.code != "200"
          @error_type = :unknown
          @error_info = "#{response.code}: #{response.body}"
          return false
        else
          success = true
          @build_id = response.body
        end
      end

      [ success, @build_id, @server_uri ]
    end

    def stop_run
      log "Notifying server we want to stop the run" do
        HTTParty.delete("#{@server_uri}/builds/#{@build_id}")
      end
    end

    def on_new_results
      last_results_size = 0
      error_count = 0
      loop do 
        requester.send(:sleep, 0.5)

        begin
          @build = HTTParty.get("#{server_uri}/builds/#{build_id}", :format => :json)
          next unless @build
        rescue Exception => ex
          error_count += 1
          if error_count > 4
            requester.puts "Failed to get status: #{ex.message}"
            error_count = 0
          end
          next
        end

        results = @build['results'][last_results_size..-1]
        last_results_size = @build['results'].size

        unless results == ''
          yield results
        end

        break if @build['done']
      end
    end

    def result_summary
      adapter.sum_results(@build['results']) if adapter.respond_to?(:sum_results)
    end

    def build_successful?
      build["success"]
    end

    attr_reader :build, :error_type, :error_info

    private

    attr_reader :config, :adapter, :requester, :server_uri, :build_id

    def rsync_uri
      localhost? ? config.rsync_path : "#{config.server_user}@#{config.server_host}:#{config.rsync_path}"
    end

    def root
      if localhost?
        config.rsync_path
      else
        "#{config.server_user}@#{config.server_host}:#{config.rsync_path}"
      end
    end

    def localhost?
      [ '0.0.0.0', 'localhost', '127.0.0.1' ].include?(config.server_host)
    end

    def jruby?
      RUBY_PLATFORM =~ /java/ || !!ENV['USE_JRUBY']
    end

    def log(text)
      if config.logging
        print "#{text}... "; STDOUT.flush
        yield
        puts "done"
      else
        yield
      end
    end
  end
end

