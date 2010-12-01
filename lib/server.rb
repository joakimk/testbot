require 'rubygems'
require 'sinatra'
require 'yaml'
require 'json'
require File.join(File.dirname(__FILE__), 'server/job.rb')
require File.join(File.dirname(__FILE__), 'server/group.rb') unless defined?(Group)
require File.join(File.dirname(__FILE__), 'server/runner.rb')
require File.join(File.dirname(__FILE__), 'server/build.rb')
require File.expand_path(File.join(File.dirname(__FILE__), 'testbot'))

if ENV['INTEGRATION_TEST']
  set :port, 22880
else
  set :port, Testbot::SERVER_PORT
end

disable :logging if ENV['DISABLE_LOGGING']

class Server
  def self.valid_version?(runner_version)
    Testbot::VERSION == runner_version
  end
end

post '/builds' do
  build = Build.create_and_build_jobs(params)[:id].to_s
end

get '/builds/:id' do
  build = Build.find(:id => params[:id].to_i)
  build.destroy if build[:done]
  { "done" => build[:done], "results" => build[:results], "success" => build[:success] }.to_json
end

get '/jobs/next' do
  next_job, runner = Job.next(params, @env['REMOTE_ADDR'])
  if next_job
    next_job.update(:taken_at => Time.now, :taken_by_id => runner.id)
    [ next_job[:id], next_job[:requester_mac], next_job[:project], next_job[:root], next_job[:type], (next_job[:jruby] == 1 ? 'jruby' : 'ruby'), next_job[:files] ].join(',')
  end
end

put '/jobs/:id' do
  Job.find(:id => params[:id].to_i).update(:result => params[:result], :success => params[:success]); nil
end

get '/runners/ping' do
  return unless Server.valid_version?(params[:version])
  runner = Runner.find(:uid => params[:uid])
  runner.update(params.merge({ :last_seen_at => Time.now })) if runner
  nil
end

get '/runners/outdated' do
  Runner.find_all_outdated.map { |runner| [ runner[:ip], runner[:hostname], runner[:uid] ].join(' ') }.join("\n").strip
end

get '/runners/available_instances' do
  Runner.available_instances.to_s
end

get '/runners/total_instances' do
  Runner.total_instances.to_s
end

get '/runners/available' do
  Runner.find_all_available.map { |runner| [ runner[:ip], runner[:hostname], runner[:uid], runner[:username], runner[:idle_instances] ].join(' ') }.join("\n").strip
end

get '/version' do
  Testbot::VERSION
end
