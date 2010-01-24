require 'rubygems'
require 'sinatra'
require 'sequel'

class Server
  def self.version
    2
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
  Boolean :taken, :default => false
end

DB.create_table :runners do
  primary_key :id
  String :ip
  String :hostname
  String :mac
  Integer :version
  Integer :idle_instances
  Datetime :last_seen_at
end

class Job < Sequel::Model; end

class Runner < Sequel::Model

  def self.record!(hash)
    if (runner = find(:mac => hash[:mac]))
      runner.update hash
    else
      Runner.create hash
    end    
  end
  
  def self.find_all_outdated
    DB[:runners].filter("version < ? OR version IS NULL", Server.version)
  end
  
  def self.available_instances
    DB[:runners].filter("version = ? AND last_seen_at > ?", Server.version, Time.now - 3).inject(0) { |sum, r| r[:idle_instances] + sum }
  end
  
end

before do
  @@config ||= YAML.load_file("~/.testbot_server.yml")
end

class Sinatra::Application
  def config
    OpenStruct.new(@@config)
  end  
end

post '/jobs' do
  Job.create(params)[:id].to_s
end

get '/jobs/next' do
  Runner.record! params.merge({ :ip => @env['REMOTE_ADDR'], :last_seen_at => Time.now })
  return unless Server.valid_version?(params[:version])
  next_job = Job.find(:taken => false) or return
  next_job.update(:taken => true)
  [ next_job[:id], next_job[:root], next_job[:files] ].join(',')
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

get '/version' do
  Server.version.to_s
end

get '/update_uri' do
  config.update_uri
end
