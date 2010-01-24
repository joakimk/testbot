require File.join(File.dirname(__FILE__), '../lib/server')
require 'test/unit'
require 'rack/test'

set :environment, :test

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    DB[:jobs].delete
    DB[:runners].delete
  end

  def app
    Sinatra::Application
  end

  def test_it_should_save_a_job_and_return_the_id
    post '/jobs', :files => 'spec/models/car_spec.rb spec/models/house_spec.rb', :root => 'server:/path/to/project'
    first_job = Job.first
    assert last_response.ok?    
    assert_equal first_job[:id].to_s, last_response.body
    assert_equal 'spec/models/car_spec.rb spec/models/house_spec.rb', first_job[:files]
    assert_equal 'server:/path/to/project', first_job[:root]
  end
  
  def test_it_should_be_able_to_return_a_job_and_mark_it_as_taken
    job1 = Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project'
    job2 = Job.create :files => 'spec/models/house_spec.rb'
    get '/jobs/next', :version => Server.version
    assert last_response.ok?      
    assert_equal [ job1[:id], "server:/project", "spec/models/car_spec.rb" ].join(','), last_response.body
    assert job1.reload[:taken]
    assert !job2.reload[:taken]
  end
  
  def test_it_should_not_return_a_job_that_has_already_been_taken
    job1 = Job.create :files => 'spec/models/car_spec.rb', :taken => true
    job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project' 
    get '/jobs/next', :version => Server.version
    assert last_response.ok?
    assert_equal [ job2[:id], "server:/project", "spec/models/house_spec.rb" ].join(','), last_response.body
    assert job2.reload[:taken]    
  end

  def test_it_should_not_return_a_job_if_there_isnt_any
    get '/jobs/next', :version => Server.version
    assert last_response.ok?
    assert_equal '', last_response.body
  end
  
  def test_it_should_save_information_about_the_runners
    get '/jobs/next', :version => "1", :hostname => 'macmini.local', :mac => "00:01:..."
    runner = DB[:runners].first
    assert_equal 1,           runner[:version]
    assert_equal '127.0.0.1', runner[:ip]
    assert_equal 'macmini.local', runner[:hostname]
    assert_equal '00:01:...', runner[:mac]
    assert (Time.now - 5) < runner[:last_seen_at]
    assert (Time.now + 5) > runner[:last_seen_at]
  end
  
  def test_it_should_only_create_one_record_for_the_same_mac
    get '/jobs/next', :version => "1", :hostname => 'macmini.local1', :mac => "00:01:..."
    get '/jobs/next', :version => "1", :hostname => 'macmini.local2', :mac => "00:01:..."
    assert_equal 1, Runner.count
  end
  
  def test_it_should_not_return_anything_to_outdated_clients
    Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project'
    get '/jobs/next', :version => "1", :hostname => 'macmini.local', :mac => "00:..."
    assert last_response.ok?
    assert_equal '', last_response.body
  end
  
  def test_it_should_be_able_to_return_a_list_of_outdated_runners
    get '/jobs/next', :version => "1", :hostname => 'macmini1.local', :mac => "00:01"
    get '/jobs/next', :version => "1", :hostname => 'macmini2.local', :mac => "00:02"
    get '/jobs/next'    
    get '/jobs/next', :version => Server.version.to_s, :hostname => 'macmini3.local', :mac => "00:03"
    assert_equal 4, Runner.count
    get '/runners/outdated'
    assert last_response.ok?
    assert_equal "127.0.0.1 macmini1.local 00:01\n127.0.0.1 macmini2.local 00:02\n127.0.0.1", last_response.body
  end
  
  def test_it_should_be_able_to_return_a_list_of_available_runners
    get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01"
    get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02"
    get '/runners/available_count'
    assert last_response.ok?
    assert_equal "2", last_response.body
  end
  
  def test_it_should_not_list_runners_as_available_when_not_seen_the_last_second_three_seconds
    get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01"
    get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02"
    Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 3)
    get '/runners/available_count'
    assert last_response.ok?
    assert_equal "1", last_response.body
  end
 
  def test_it_should_be_able_to_receive_the_results_of_a_job
    job = Job.create :files => 'spec/models/car_spec.rb', :taken => true
    put "/jobs/#{job[:id]}", :result => 'test run result'
    assert last_response.ok?
    assert_equal 'test run result', job.reload.result
  end
  
  def test_it_should_be_able_to_return_the_status_of_a_job
    job = Job.create :result => 'test run result'
    get "/jobs/#{job[:id]}"
    assert last_response.ok?
    assert_equal 'test run result', last_response.body
  end
  
  def test_it_should_be_able_to_return_the_status_of_a_not_complete_job
    job = Job.create
    get "/jobs/#{job[:id]}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end  
  
  def test_it_should_be_possible_to_delete_a_job
    job = Job.create
    delete "/jobs/#{job[:id]}"
    assert_equal 0, Job.count
  end
end
