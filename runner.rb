require 'rubygems'
require 'httparty'

class Server
  include HTTParty
  base_uri "http://localhost:4567"
end

loop do
  sleep 1
  next_job = Server.get("/jobs/next") rescue nil
  next if next_job == nil
  id, root, specs = next_job.split(',')
  system "rsync -az --delete -e ssh #{root}/ project"
  result = `export RAILS_ENV=test; cd project; pwd; script/spec -O spec/spec.opts #{specs}`
  Server.put("/jobs/#{id}", :query => { :result => result })
end
