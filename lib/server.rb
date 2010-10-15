require 'rubygems'
require 'sinatra'
require 'sequel'
require 'yaml'

set :port, 2288

class Server
  def self.version
    17
  end
  
  def self.valid_version?(runner_version)
    version == runner_version.to_i
  end
end

DB = Sequel.sqlite

DB.create_table :jobs do
  primary_key :id
  String :files
  String :result
  String :root
  String :type
  String :server_type
  String :requester_ip
  Boolean :taken, :default => false
end

DB.create_table :runners do
  primary_key :id
  String :ip
  String :hostname
  String :mac
  Integer :version
  Integer :idle_instances
  Integer :max_instances
  Datetime :last_seen_at
end

class Job < Sequel::Model; end

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

post '/jobs' do
  Job.create(params.merge({ :requester_ip => @env['REMOTE_ADDR'] }))[:id].to_s
end

get '/jobs/next' do
  params_without_requester_ip = params.reject { |k, v| k == "requester_ip" }  
  Runner.record! params_without_requester_ip.merge({ :ip => @env['REMOTE_ADDR'], :last_seen_at => Time.now })
  return unless Server.valid_version?(params[:version])
  next_job = Job.find(:taken => false) or return
  next_job.update(:taken => true)
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
