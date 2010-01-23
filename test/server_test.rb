require File.join(File.dirname(__FILE__), '../lib/server')
require 'test/unit'
require 'rack/test'

set :environment, :test

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    DB[:jobs].delete
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
    get '/jobs/next'
    assert last_response.ok?      
    assert_equal [ job1[:id], "server:/project", "spec/models/car_spec.rb" ].join(','), last_response.body
    assert job1.reload[:taken]
    assert !job2.reload[:taken]
  end
  
  def test_it_should_not_return_a_job_that_has_already_been_taken
    job1 = Job.create :files => 'spec/models/car_spec.rb', :taken => true
    job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project' 
    get '/jobs/next'
    assert last_response.ok?
    assert_equal [ job2[:id], "server:/project", "spec/models/house_spec.rb" ].join(','), last_response.body
    assert job2.reload[:taken]    
  end

  def test_it_should_not_return_a_job_if_there_isnt_any
    get '/jobs/next'
    assert last_response.ok?
    assert_equal '', last_response.body
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
