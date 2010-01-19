# Config
SERVER = "http://localhost:4567"

require 'rubygems'
require 'httparty'

class Server
  include HTTParty
  base_uri SERVER
end

loop do
  sleep 1
  next_job = Server.get("/jobs/next") rescue nil
  next if next_job == nil
  id, root, specs = next_job.split(',')
  puts "Syncing..."
  system "rsync -az --delete -e ssh #{root}/ project"
  puts "Running job #{id}..."
  result = `export RAILS_ENV=test; cd project; rake testbot:prepare; script/spec -O spec/spec.opts #{specs}`
  puts "Done"
  Server.put("/jobs/#{id}", :query => { :result => result })
end
