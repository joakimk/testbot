require 'rubygems'
require 'httparty'

class NewRequester
  
  def initialize(server_uri, server_path, server_type)
    @server_uri, @server_path, @server_type = server_uri, server_path, server_type
  end
  
  def run_tests(type, dir)
    files = find_tests(type, dir)
    build_id = HTTParty.post("#{@server_uri}/builds", :body => { :root => @server_path,
                                                                 :server_type => @server_type,
                                                                 :type => type.to_s,
                                                                 :files => files.join(' ') })

    last_results_size = 0
    while true
      sleep 1
      
      build = HTTParty.get("#{@server_uri}/builds/#{build_id}", :format => :json)

      puts build['results'][last_results_size..-1]
      last_results_size = build['results'].size
      
      break if build['done']
    end
  end
  
  def self.create_by_config(path)
    config = YAML.load_file(path)
    NewRequester.new(config['server_uri'], config['server_path'], config['server_type'])
  end
  
  private
  
  def find_tests(type, dir)
    root = "#{dir}/"
    if type == :rspec
      Dir["#{root}**/**/*_spec.rb"]
    else
      raise "unsupported type: #{type}"
    end
  end
  
end
