require 'rubygems'
require 'sinatra'
require 'sequel'

DB = Sequel.sqlite

DB.create_table :jobs do
  primary_key :id
  String :files
  String :result
  String :root
  Boolean :taken, :default => false
end

class Job < Sequel::Model; end

post '/jobs' do
  Job.create(params)[:id].to_s
end

get '/jobs/next' do
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
