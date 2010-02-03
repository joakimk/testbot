require 'rubygems'
require 'httparty'

class Server
  include HTTParty
end

class NewRunner
  
  def self.run_jobs
    next_job = Server.get('/jobs/next') rescue nil
    return unless next_job
    id, root, specs = next_job.split(',')
    result = run_and_return_results("export RAILS_ENV=test; export RSPEC_COLOR=true; rake testbot:before_run; script/spec -O spec/spec.opts #{specs}")
    Server.put("/jobs/#{id}", :body => { :result => result })
  end
  
  def self.load_config
    Server.base_uri YAML.load_file("#{ENV['HOME']}/.testbot_runner.yml")[:server_uri]
  end

  private

  # I'd really like to know how to do this better and more testable
  def self.run_and_return_results(cmd)
    `#{cmd} 2>&1`
  end
  
end