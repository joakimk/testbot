require 'rubygems'
require 'httparty'

class Server
  include HTTParty
  base_uri "http://localhost:4567"
end

job_id = Server.post('/jobs', :query => { :files => 'spec/models/car.rb spec/models/house.rb' })

result = nil
loop do
  sleep 1
  result = Server.get("/jobs/#{job_id}")
  break unless result == nil
end

Server.delete("/jobs/#{job_id}")

puts result
