require 'rubygems'
require 'httparty'
require 'macaddr'
require 'ostruct'
require File.dirname(__FILE__) + '/shared/ssh_tunnel'

class Requester
  
  attr_reader :config
  
  def initialize(config = {})
    @config = OpenStruct.new(config)
  end
  
  def run_tests(type, dir)
    SSHTunnel.new(*config.ssh_tunnel.split('@').reverse).open if config.ssh_tunnel

    if config.server_type == 'rsync'
      ignores = config.ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
      system "rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh #{ignores} . #{config.server_path}"
    end
    
    files = find_tests(type, dir)
    build_id = HTTParty.post("#{config.server_uri}/builds", :body => { :root => config.server_path,
                                                       :server_type => config.server_type,
                                                       :type => type.to_s,
                                                       :requester_mac => Mac.addr,
                                                       :available_runner_usage => config.available_runner_usage,
                                                       :files => files.join(' ') })
    last_results_size = 0
    success = true
    error_count = 0
    while true
      sleep 1
      
      begin
        @build = HTTParty.get("#{config.server_uri}/builds/#{build_id}", :format => :json)
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
  
  def find_tests(type, dir)
    root = "#{dir}/"
    if type == :rspec
      Dir["#{root}**/**/*_spec.rb"]
    elsif type == :cucumber
      Dir["#{root}**/**/*.feature"]
    else
      raise "unsupported type: #{type}"
    end
  end
  
end

if ENV['INTEGRATION_TEST']
  requester = Requester.create_by_config('config/testbot.yml')
  requester.run_tests(:rspec, 'spec')
end
