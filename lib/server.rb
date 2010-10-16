require 'rubygems'
require 'sinatra'
require 'yaml'
require 'json'
require File.join(File.dirname(__FILE__), 'server/runtime.rb')

if ENV['INTEGRATION_TEST']
  set :port, 22880
else
  set :port, 2288
end

class Server
  def self.version
    20
  end
  
  def self.valid_version?(runner_version)
    version == runner_version.to_i
  end
end

class Job < Sequel::Model
  def update(hash)
    super(hash)
    if build = Build.find([ "id = ?", self[:build_id] ])
      done = Job.filter([ "result IS NULL AND build_id = ?", self[:build_id] ]).count == 0
      build.update(:results => build[:results].to_s + hash[:result].to_s,
                   :done => done)
    end
    Runtime.store_results(self[:files].split(' '), Time.now - self[:taken_at], self[:type])
  end
end

class Build < Sequel::Model

  def self.create_and_build_jobs(hash)
    build = create(hash.reject { |k, v| k == 'available_runner_usage' })
    build.create_jobs!(hash['available_runner_usage'])
    build
  end
  
  def create_jobs!(available_runner_usage)
    groups = Runtime.build_groups(self[:files].split,
                     Runner.total_instances.to_f * (available_runner_usage.to_i / 100.0), self[:type])
    groups.each do |group|
      Job.create(:files => group.join(' '),
                 :root => self[:root],
                 :type => self[:type],
                 :server_type => self[:server_type],
                 :requester_ip => self[:requester_ip],
                 :build_id => self[:id])
    end
  end
  
end

class Runner < Sequel::Model

  def self.record!(hash)
    runner = create_or_update_by_mac!(hash)
    
    if runner[:idle_instances].to_i > runner[:max_instances].to_i
      runner.update :max_instances => runner[:idle_instances]
    end
  end
  
  def self.create_or_update_by_mac!(hash)
    if (runner = find(:mac => hash[:mac]))
      runner.update hash
    else
      Runner.create hash
    end
  end
  
  def self.find_all_outdated
    DB[:runners].filter("version < ? OR version IS NULL", Server.version)
  end
  
  def self.find_all_available
    DB[:runners].filter("version = ? AND last_seen_at > ?", Server.version, Time.now - 3)
  end  
  
  def self.available_instances
    find_all_available.inject(0) { |sum, r| r[:idle_instances] + sum }
  end
  
  def self.total_instances
    return 1 if ENV['INTEGRATION_TEST']
    DB[:runners].filter("version = ? AND last_seen_at > ?", Server.version, Time.now - 3600).inject(0) { |sum, r| r[:max_instances] + sum }
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
  build = Build.create_and_build_jobs(params.merge({ :requester_ip => @env['REMOTE_ADDR'] }))[:id].to_s
end

get '/builds/:id' do
  build = Build.find(:id => params[:id].to_i)
  build.destroy if build[:done]
  { "done" => build[:done], "results" => build[:results] }.to_json
end

post '/jobs' do
  Job.create(params.merge({ :requester_ip => @env['REMOTE_ADDR'] }))[:id].to_s
end

get '/jobs/next' do
  params_without_requester_ip = params.reject { |k, v| k == "requester_ip" }
  Runner.record! params_without_requester_ip.merge({ :ip => @env['REMOTE_ADDR'], :last_seen_at => Time.now })
  return unless Server.valid_version?(params[:version])

  if params["requester_ip"]
    next_job = Job.find("taken_at IS NULL AND requester_ip = '#{params["requester_ip"]}'") or return
  else
    next_job = Job.find("taken_at IS NULL") or return
  end
    
  next_job.update(:taken_at => Time.now)
  [ next_job[:id], next_job[:requester_ip], next_job[:root], next_job[:type], next_job[:server_type], next_job[:files] ].join(',')
end

put '/jobs/:id' do
  Job.find(:id => params[:id].to_i).update(:result => params[:result]); nil
end

get '/jobs/:id' do
  Job.find(:id => params[:id].to_i)[:result]
end

delete '/jobs/:id' do
  Job.find(:id => params[:id].to_i).delete; nil
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
  Runner.find_all_available.map { |runner| [ runner[:ip], runner[:hostname], runner[:mac], runner[:idle_instances] ].join(' ') }.join("\n").strip
end

get '/version' do
  Server.version.to_s
end

get '/update_uri' do
  config.update_uri
end
