require 'rubygems'
require 'sinatra'
require 'sequel'

DB = Sequel.sqlite

DB.create_table :jobs do
  primary_key :id
  String :files
  String :result
  Boolean :taken, :default => false
end

class Job < Sequel::Model; end

post '/jobs' do
  Job.create(params)[:id].to_s
end

get '/jobs/next' do
  next_job = Job.find :taken => false
  return unless next_job
  next_job.update(:taken => true)
  "#{next_job[:id]},#{next_job[:files]}"
end

put '/jobs/:id' do
  Job.find(params[:id]).update(:result => params[:result]); nil
end

get '/jobs/:id' do
  Job.find(params[:id])[:result]
end

delete '/jobs/:id' do
  Job.find(params[:id]).delete; nil
end
