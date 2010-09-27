require File.join(File.dirname(__FILE__), '../lib/server')
require 'test/unit'
require 'rack/test'
require 'shoulda'
require 'flexmock/test_unit'

set :environment, :test

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    DB[:jobs].delete
    DB[:runners].delete
    flexmock(YAML).should_receive("load_file").with("#{ENV['HOME']}/.testbot_server.yml").and_return({ :update_uri => "http://somewhere/file.tar.gz" })
  end

  def app
    Sinatra::Application
  end

  context "POST /jobs" do

    should "save a job and return the id" do
      post '/jobs', :files => 'spec/models/car_spec.rb spec/models/house_spec.rb', :root => 'server:/path/to/project', :type => 'rspec', :server_type => 'rsync'
      first_job = Job.first
      assert last_response.ok?    
      assert_equal first_job[:id].to_s, last_response.body
      assert_equal 'spec/models/car_spec.rb spec/models/house_spec.rb', first_job[:files]
      assert_equal 'server:/path/to/project', first_job[:root]
      assert_equal 'rspec', first_job[:type]
      assert_equal 'rsync', first_job[:server_type]
    end
    
  end
  
  context "GET /jobs/next" do
  
    should "be able to return a job and mark it as taken" do
      job1 = Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project', :type => 'rspec', :server_type => 'rsync'
      job2 = Job.create :files => 'spec/models/house_spec.rb', :type => 'rspec'
      get '/jobs/next', :version => Server.version
      assert last_response.ok?      
      assert_equal [ job1[:id], "server:/project", "rspec", "rsync", "spec/models/car_spec.rb" ].join(','), last_response.body
      assert job1.reload[:taken]
      assert !job2.reload[:taken]
    end
  
    should "not return a job that has already been taken" do
      job1 = Job.create :files => 'spec/models/car_spec.rb', :taken => true, :type => 'rspec'
      job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'rspec', :server_type => "rsync"
      get '/jobs/next', :version => Server.version
      assert last_response.ok?
      assert_equal [ job2[:id], "server:/project", "rspec", "rsync", "spec/models/house_spec.rb" ].join(','), last_response.body
      assert job2.reload[:taken]    
    end

    should "not return a job if there isnt any" do
      get '/jobs/next', :version => Server.version
      assert last_response.ok?
      assert_equal '', last_response.body
    end
  
    should "save information about the runners" do
      get '/jobs/next', :version => "1", :hostname => 'macmini.local', :mac => "00:01:...", :idle_instances => 2
      runner = DB[:runners].first
      assert_equal 1,           runner[:version]
      assert_equal '127.0.0.1', runner[:ip]
      assert_equal 'macmini.local', runner[:hostname]
      assert_equal '00:01:...', runner[:mac]
      assert_equal 2, runner[:idle_instances]
      assert (Time.now - 5) < runner[:last_seen_at]
      assert (Time.now + 5) > runner[:last_seen_at]
    end
  
    should "only create one record for the same mac" do
      get '/jobs/next', :version => "1", :hostname => 'macmini.local1', :mac => "00:01:..."
      get '/jobs/next', :version => "1", :hostname => 'macmini.local2', :mac => "00:01:..."
      assert_equal 1, Runner.count
    end
  
    should "not return anything to outdated clients" do
      Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project'
      get '/jobs/next', :version => "1", :hostname => 'macmini.local', :mac => "00:..."
      assert last_response.ok?
      assert_equal '', last_response.body
    end
    
  end
  
  context "/runners/outdated" do
    
    should "return a list of outdated runners" do
      get '/jobs/next', :version => "1", :hostname => 'macmini1.local', :mac => "00:01"
      get '/jobs/next', :version => "1", :hostname => 'macmini2.local', :mac => "00:02"
      get '/jobs/next'    
      get '/jobs/next', :version => Server.version.to_s, :hostname => 'macmini3.local', :mac => "00:03"
      assert_equal 4, Runner.count
      get '/runners/outdated'
      assert last_response.ok?
      assert_equal "127.0.0.1 macmini1.local 00:01\n127.0.0.1 macmini2.local 00:02\n127.0.0.1", last_response.body
    end
    
  end

  context "GET /runners/available_runners" do

    should "return a list of available runners" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      get '/runners/available'
      assert last_response.ok?
      assert_equal "127.0.0.1 macmini1.local 00:01 2\n127.0.0.1 macmini2.local 00:02 4", last_response.body
    end
    
    should "not return runners as available when not seen the last three seconds" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 3)      
      get '/runners/available'
      assert_equal "127.0.0.1 macmini1.local 00:01 2", last_response.body
    end
    
  end
  
  context "GET /runners/available_instances" do
    
    should "return the number of available runner instances" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      get '/runners/available_instances'
      assert last_response.ok?
      assert_equal "6", last_response.body
    end    
        
    should "not return instances as available when not seen the last three seconds" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 3)
      get '/runners/available_instances'
      assert last_response.ok?
      assert_equal "2", last_response.body
    end    
    
  end
  
  context "PUT /jobs/:id" do

    should "receive the results of a job" do
       job = Job.create :files => 'spec/models/car_spec.rb', :taken => true
       put "/jobs/#{job[:id]}", :result => 'test run result'
       assert last_response.ok?
       assert_equal 'test run result', job.reload.result
     end

  end
  
  context "GET /jobs/:id" do

     should "return the status of a job" do
       job = Job.create :result => 'test run result'
       get "/jobs/#{job[:id]}"
       assert last_response.ok?
       assert_equal 'test run result', last_response.body
     end

     should "be able to return the status of a non complete job" do
       job = Job.create
       get "/jobs/#{job[:id]}"
       assert last_response.ok?
       assert_equal '', last_response.body
     end  
  
  end
  
  context "DELETE /jobs/:id" do

    should "delete the job" do
      job = Job.create
      delete "/jobs/#{job[:id]}"
      assert_equal 0, Job.count
    end

  end
  
  context "GET /version" do
  
    should "return its version" do
      get '/version'
      assert last_response.ok?
      assert_equal Server.version.to_s, last_response.body
    end

  end
  
  context "GET /update_uri" do
    
    should "return the configured update URI" do
      get '/update_uri'
      assert last_response.ok?
      assert_equal "http://somewhere/file.tar.gz", last_response.body
    end
    
  end
 
end
