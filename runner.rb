require 'rubygems'
require 'httparty'

class Server
  include HTTParty
  base_uri "http://localhost:4567"
end

loop do
  sleep 1
  next_job = Server.get("/jobs/next")
  next if next_job == nil
  id, work = next_job.split(',')
  puts "Work to do: #{work}"
  Server.put("/jobs/#{id}", :query => { :result => 'foo' })
end
