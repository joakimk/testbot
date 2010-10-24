require 'rubygems'
require 'sinatra'
require 'yaml'
require 'json'
require File.join(File.dirname(__FILE__), 'server/job.rb')
require File.join(File.dirname(__FILE__), 'server/group.rb') unless defined?(Group)
require File.join(File.dirname(__FILE__), 'server/runner.rb')
require File.join(File.dirname(__FILE__), 'server/build.rb')

if ENV['INTEGRATION_TEST']
  set :port, 22880
else
  set :port, 2288
end

class Server
  def self.version
    32
  end
  
  def self.valid_version?(runner_version)
    version == runner_version.to_i
  end
end

before do
  @@config ||= ENV['INTEGRATION_TEST'] ? { :update_uri => '' } : YAML.load_file("#{ENV['HOME']}/.testbot_server.yml")
end

class Sinatra::Application
  def config
    OpenStruct.new(@@config)
  end  
end

post '/builds' do
  build = Build.create_and_build_jobs(params)[:id].to_s
end

get '/builds/:id' do
  build = Build.find(:id => params[:id].to_i)
  build.destroy if build[:done]
  { "done" => build[:done], "results" => build[:results] }.to_json
end

get '/jobs/next' do
  next_job, runner = Job.next(params, @env['REMOTE_ADDR'])
  if next_job
    next_job.update(:taken_at => Time.now, :taken_by_id => runner.id)
    [ next_job[:id], next_job[:requester_mac], next_job[:project], next_job[:root], next_job[:type], next_job[:server_type], next_job[:files] ].join(',')
  end
end

put '/jobs/:id' do
  Job.find(:id => params[:id].to_i).update(:result => params[:result]); nil
end

get '/runners/ping' do
  return unless Server.valid_version?(params[:version])
  runner = Runner.find(:mac => params[:mac])
  runner.update(params.merge({ :last_seen_at => Time.now })) if runner
  nil
end

get '/runners/outdated' do
  Runner.find_all_outdated.map { |runner| [ runner[:ip], runner[:hostname], runner[:mac] ].join(' ') }.join("\n").strip
end

get '/runners/available_instances' do
  Runner.available_instances.to_s
end

get '/runners/total_instances' do
  Runner.total_instances.to_s
end

get '/runners/available' do
  Runner.find_all_available.map { |runner| [ runner[:ip], runner[:hostname], runner[:mac], runner[:username], runner[:idle_instances] ].join(' ') }.join("\n").strip
end

get '/version' do
  Server.version.to_s
end

get '/update_uri' do
  config.update_uri
end
