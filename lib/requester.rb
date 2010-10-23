require 'rubygems'
require 'httparty'
require 'macaddr'
require 'ostruct'
require File.dirname(__FILE__) + '/shared/ssh_tunnel'
require File.dirname(__FILE__) + '/adapters/adapter'

class Requester
  
  attr_reader :config

  def initialize(config = {})
    @config = OpenStruct.new(config)
  end
  
  def run_tests(adapter, dir)
    if config.ssh_tunnel
      user, host = config.ssh_tunnel.split('@')
      SSHTunnel.new(host, user, adapter.requester_port).open
      server_uri = "http://127.0.0.1:#{adapter.requester_port}"
    else
      server_uri = config.server_uri
    end

    if config.server_type == 'rsync'
      ignores = config.ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
      system "rsync -az --delete -e ssh #{ignores} . #{config.server_path}"
    end
        
    files = find_tests(adapter, dir)
    
    build_id = HTTParty.post("#{server_uri}/builds", :body => { :root => config.server_path,
                                                     :server_type => config.server_type,
                                                     :type => adapter.type.to_s,
                                                     :project => config.project,
                                                     :requester_mac => Mac.addr,
                                                     :available_runner_usage => config.available_runner_usage,
                                                     :files => files.join(' ') })
                                                     

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
      puts results unless results == ''
      last_results_size = @build['results'].size
      
      success = false if failed_build?(@build)
      break if @build['done']
    end
    
    success
  end
  
  def self.create_by_config(path)
    Requester.new(YAML.load_file(path))
  end
  
  def result_lines
    @build['results'].find_all { |line| line_is_result?(line) }.map { |line| line.chomp }
  end
  
  private
  
  def failed_build?(build)
    result_lines.any? { |line| line_is_failure?(line) }
  end
  
  def line_is_result?(line)
    line =~ /\d+ fail/
  end  
  
  def line_is_failure?(line)
    line =~ /(\d{2,}|[1-9]) (fail|error)/
  end
  
  def find_tests(adapter, dir)
    Dir["#{dir}/#{adapter.file_pattern}"]
  end
  
end

if ENV['INTEGRATION_TEST']
  requester = Requester.create_by_config('config/testbot.yml')
  requester.run_tests(RSpecAdapter, 'spec')
end
