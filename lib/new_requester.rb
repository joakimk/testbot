require 'rubygems'
require 'httparty'

class NewRequester
  
  def initialize(server_uri, server_path, server_type, ignores = '')
    @server_uri, @server_path, @server_type, @ignores = server_uri, server_path, server_type, ignores
  end
  
  def run_tests(type, dir)
    if @server_type == 'rsync'
      ignores = @ignores.split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
      system "rake testbot:before_request &> /dev/null; rsync -az --delete -e ssh #{ignores} . #{@server_path}"
    end
    
    files = find_tests(type, dir)
    build_id = HTTParty.post("#{@server_uri}/builds", :body => { :root => @server_path,
                                                                 :server_type => @server_type,
                                                                 :type => type.to_s,
                                                                 :files => files.join(' ') })
    last_results_size = 0
    success = true
    while true
      sleep 1
      
      build = HTTParty.get("#{@server_uri}/builds/#{build_id}", :format => :json)

      results = build['results'][last_results_size..-1]
      puts results unless results == ''
      last_results_size = build['results'].size
      
      success = false if failed_build?(build)
      break if build['done']
    end
    
    success
  end
  
  def self.create_by_config(path)
    config = YAML.load_file(path)
    NewRequester.new(config['server_uri'], config['server_path'], config['server_type'], config['ignores'])
  end
  
  private
  
  def failed_build?(build)
    build['results'].include?('failure') || build['results'].include?('error')
  end
  
  def find_tests(type, dir)
    root = "#{dir}/"
    if type == :rspec
      Dir["#{root}**/**/*_spec.rb"]
    else
      raise "unsupported type: #{type}"
    end
  end
  
end

if ENV['INTEGRATION_TEST']
  requester = NewRequester.create_by_config('config/testbot.yml')
  requester.run_tests(:rspec, 'spec')
end
