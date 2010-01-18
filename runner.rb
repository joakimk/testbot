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
  id, root, specs = next_job.split(',')
  puts "rsync -az --delete -e ssh --exclude='database.yml' --exclude='.git/*' --exclude='log/*' #{root} testbotdata"
  puts "export RAILS_ENV=test; script/spec -O spec/spec.opts #{specs}"
  sleep 5
  Server.put("/jobs/#{id}", :query => { :result => 'foo' })
end
