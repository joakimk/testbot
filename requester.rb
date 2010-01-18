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

requester = Requester.new("http://localhost:4567", "server:/path/to/project")
requester.request_job("spec/models/car_spec.rb spec/models/house_spec.rb")
