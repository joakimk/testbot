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

system "rsync -az --delete -e ssh . ../../../tmp/server"

requester = Requester.new("http://localhost:4567", "../../tmp/server")
requester.request_job(find_specs)

