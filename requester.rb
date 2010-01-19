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
    Server.post('/jobs', :body => { :root => @project_path, :files => files })
  end
  
  def poll(job_id)
    result = Server.get("/jobs/#{job_id}")
    Server.delete("/jobs/#{job_id}") if result != nil
    result
  end
  
end

def find_specs
  Dir["spec/**/*_spec.rb"].map { |path| path.gsub(/#{Dir.pwd}\//, '') }
end

def specs_in_groups(num)
  specs = find_specs
  return [ specs ] if num == 1
  groups = []
  current_group = 0
  specs.each do |test|    
    if groups[current_group] && groups[current_group].size >= (specs.size / num.to_f)
      current_group += 1
    end
    groups[current_group] ||= []
    groups[current_group] << test
  end
  groups.compact
end

start = Time.now

settings = YAML.load_file("config/testbot.yml")

ignores = settings['ignores'].split.map { |pattern| "--exclude='#{pattern}'" }.join(' ')
system "rsync -az --delete -e ssh #{ignores} . #{settings['server_path']}"

requester = Requester.new(settings["server"], settings['server_path'])

job_ids = specs_in_groups(settings['groups'].to_i).map do |specs|
  requester.request_job(specs.join(' '))
end

loop do
  job_ids.each do |job_id|
    sleep 0.5
    result = requester.poll(job_id)
    next if result == nil
    puts result
    job_ids.delete(job_id)
    puts "#{job_ids.size} jobs to go..." unless job_ids.size == 0 unless ENV['INTEGRATION_TEST']
  end
  break if job_ids.size == 0
end

puts "Completed after #{Time.now - start} seconds." unless ENV['INTEGRATION_TEST']
