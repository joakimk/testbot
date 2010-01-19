require 'rubygems'
require 'httparty'


class Requester
  
  class Server
    include HTTParty    
  end
  
  def initialize(server, project_path)
    @project_path = project_path
    Server.base_uri server
  end
  
  def request_job(files)
    job_id = Server.post('/jobs', :query => { :root => @project_path, :files => files })

    result = nil
    loop do
      sleep 1
      result = Server.get("/jobs/#{job_id}")
      break unless result == nil
    end

    Server.delete("/jobs/#{job_id}")

    puts result    
  end
  
end

def find_specs
  Dir["spec/**/*_spec.rb"].map { |path| path.gsub(/#{Dir.pwd}\//, '') }.join(' ')
end

settings = YAML.load_file("config/testbot.yml")

ignores = settings['ignores'].split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
system "rsync -az --delete -e ssh #{ignores} . #{settings['server_path']}"

requester = Requester.new(settings["server"], settings['server_path'])
requester.request_job(find_specs)

