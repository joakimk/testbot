require 'rubygems'
require 'httparty'
require 'macaddr'
require 'ostruct'
require 'erb'
require File.dirname(__FILE__) + '/../shared/ssh_tunnel'
require File.expand_path(File.dirname(__FILE__) + '/../shared/testbot')

class Hash
  def symbolize_keys_without_active_support
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
    options
    end
  end
end

module Testbot::Requester

  class Requester

    attr_reader :config

    def initialize(config = {})
      config = config.symbolize_keys_without_active_support
      config[:rsync_path]             ||= Testbot::DEFAULT_SERVER_PATH
      config[:project]                ||= Testbot::DEFAULT_PROJECT
      config[:server_user]            ||= Testbot::DEFAULT_USER
      config[:available_runner_usage] ||= Testbot::DEFAULT_RUNNER_USAGE
      @config = OpenStruct.new(config)
    end

    def run_tests(adapter, dir)
      puts if config.simple_output

      if config.ssh_tunnel
        SSHTunnel.new(config.server_host, config.server_user, adapter.requester_port).open
        server_uri = "http://127.0.0.1:#{adapter.requester_port}"
      else
        server_uri = "http://#{config.server_host}:#{Testbot::SERVER_PORT}"
      end

      rsync_ignores = config.rsync_ignores.to_s.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
      system "rsync -az --delete -e ssh #{rsync_ignores} . #{rsync_uri}"

      files = adapter.test_files(dir) 
      sizes = adapter.get_sizes(files)

      build_id = HTTParty.post("#{server_uri}/builds", :body => { :root => root,
                               :type => adapter.type.to_s,
                               :project => config.project,
                               :requester_mac => Mac.addr,
                               :available_runner_usage => config.available_runner_usage,
                               :files => files.join(' '),
                               :sizes => sizes.join(' '),
                               :jruby => jruby? })


      last_results_size = 0
      success = true
      error_count = 0
      while true
        sleep 1

        begin
          @build = HTTParty.get("#{server_uri}/builds/#{build_id}", :format => :json)
          next unless @build
        rescue Exception => ex
          error_count += 1
          if error_count > 4
            puts "Failed to get status: #{ex.message}"
            error_count = 0
          end
          next
        end

        results = @build['results'][last_results_size..-1]
        unless results == ''
          if config.simple_output
            print results.gsub(/[^\.F]|Finished/, '')
            STDOUT.flush
          else
            puts results
          end
        end

        last_results_size = @build['results'].size

        break if @build['done']
      end

      puts if config.simple_output

      @build["success"]
    end

    def self.create_by_config(path)
      file_contents = File.open(path).read
      erb_processed = ERB.new(file_contents).result
      config = YAML.load(erb_processed)
      Requester.new(config)
    end

    private

    def root
      if localhost?
        config.rsync_path
      else
        "#{config.server_user}@#{config.server_host}:#{config.rsync_path}"
      end
    end

    def rsync_uri
      localhost? ? config.rsync_path : "#{config.server_user}@#{config.server_host}:#{config.rsync_path}"
    end

    def localhost?
      [ '0.0.0.0', 'localhost', '127.0.0.1' ].include?(config.server_host)
    end

    def jruby?
      RUBY_PLATFORM =~ /java/ || !!ENV['USE_JRUBY']
    end

  end

end
