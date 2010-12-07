require 'rubygems'
require 'sinatra'
require 'yaml'
require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '/../shared/testbot'))
require File.expand_path(File.join(File.dirname(__FILE__), 'memory_model.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'job.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'group.rb')) #unless defined?(Group)
require File.expand_path(File.join(File.dirname(__FILE__), 'runner.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'build.rb'))

module Testbot::Server

  if ENV['INTEGRATION_TEST']
    set :port, 22880
  else
    set :port, Testbot::SERVER_PORT
  end

  class Server
    def self.valid_version?(runner_version)
      Testbot.version == runner_version
    end
  end

  post '/builds' do
    build = Build.create_and_build_jobs(params).id.to_s
  end

  get '/builds/:id' do
    build = Build.find(params[:id])
    build.destroy if build.done
    { "done" => build.done, "results" => build.results, "success" => build.success }.to_json
  end

  get '/jobs/next' do
    next_job, runner = Job.next(params, @env['REMOTE_ADDR'])
    if next_job
      next_job.update(:taken_at => Time.now, :taken_by => runner)
      [ next_job.id, next_job.requester_mac, next_job.project, next_job.root, next_job.type, (next_job.jruby == 1 ? 'jruby' : 'ruby'), next_job.files ].join(',')
    end
  end

  put '/jobs/:id' do
    Job.find(params[:id]).update(:result => params[:result], :success => params[:success]); nil
  end

  get '/runners/ping' do
    return unless Server.valid_version?(params[:version])
    runner = Runner.find_by_uid(params[:uid])
    runner.update(params.merge({ :last_seen_at => Time.now })) if runner
    nil
  end

  get '/runners' do
    Runner.all.map { |r| r.attributes }.to_json
  end

  get '/runners/outdated' do
    Runner.find_all_outdated.map { |runner| [ runner.ip, runner.hostname, runner.uid ].join(' ') }.join("\n").strip
  end

  get '/runners/available_instances' do
    Runner.available_instances.to_s
  end

  get '/runners/total_instances' do
    Runner.total_instances.to_s
  end

  get '/runners/available' do
    Runner.find_all_available.map { |runner| [ runner.ip, runner.hostname, runner.uid, runner.username, runner.idle_instances ].join(' ') }.join("\n").strip
  end

  get '/version' do
    Testbot.version
  end

  get '/status' do
    File.read(File.join(File.dirname(__FILE__), '/status/status.html'))
  end

  get '/status/:dir/:file' do
    File.read(File.join(File.dirname(__FILE__), "/status/#{params[:dir]}/#{params[:file]}"))
  end

end

