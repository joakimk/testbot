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
    DB[:builds].delete
    flexmock(YAML).should_receive("load_file").with("#{ENV['HOME']}/.testbot_server.yml").and_return({ :update_uri => "http://somewhere/file.tar.gz" })
  end

  def app
    Sinatra::Application
  end

  context "POST /builds" do
    
    should "create a build and return its id" do
       flexmock(Runner).should_receive(:total_instances).and_return(2)
       post '/builds', :files => 'spec/models/car_spec.rb spec/models/house_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :server_type => 'rsync', :available_runner_usage => "100%", :requester_mac => "bb:bb:bb:bb:bb:bb", :project => 'things'
       
       first_build = Build.first
       assert last_response.ok?
       assert_equal first_build[:id].to_s, last_response.body
       assert_equal 'spec/models/car_spec.rb spec/models/house_spec.rb', first_build[:files]
       assert_equal 'server:/path/to/project', first_build[:root]
       assert_equal 'spec', first_build[:type]
       assert_equal 'rsync', first_build[:server_type]
       assert_equal 'bb:bb:bb:bb:bb:bb', first_build[:requester_mac]
       assert_equal 'things', first_build[:project]
       assert_equal '', first_build[:results]
    end
        
    should "create jobs from the build based on the number of total instances" do
      flexmock(Runner).should_receive(:total_instances).and_return(2)      
      flexmock(Runtime).should_receive(:build_groups).with(["spec/models/car_spec.rb", "spec/models/car2_spec.rb", "spec/models/house_spec.rb", "spec/models/house2_spec.rb"], 2, 'spec').once.and_return([
        ["spec/models/car_spec.rb", "spec/models/car2_spec.rb"],
        ["spec/models/house_spec.rb", "spec/models/house2_spec.rb"]
      ])
      
      post '/builds', :files => 'spec/models/car_spec.rb spec/models/car2_spec.rb spec/models/house_spec.rb spec/models/house2_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :server_type => 'rsync', :available_runner_usage => "100%", :requester_mac => "bb:bb:bb:bb:bb:bb", :project => 'things'
      
      assert_equal 2, Job.count
      first_job, last_job = Job.all
      assert_equal 'spec/models/car_spec.rb spec/models/car2_spec.rb', first_job[:files]
      assert_equal 'spec/models/house_spec.rb spec/models/house2_spec.rb', last_job[:files]

      assert_equal 'server:/path/to/project', first_job[:root]
      assert_equal 'spec', first_job[:type]
      assert_equal 'rsync', first_job[:server_type]
      assert_equal 'bb:bb:bb:bb:bb:bb', first_job[:requester_mac]
      assert_equal 'things', first_job[:project]
      assert_equal Build.first[:id], first_job[:build_id]
    end
    
    should "only use resources according to available_runner_usage" do
      flexmock(Runner).should_receive(:total_instances).and_return(4)
      flexmock(Runtime).should_receive(:build_groups).with(["spec/models/car_spec.rb", "spec/models/car2_spec.rb", "spec/models/house_spec.rb", "spec/models/house2_spec.rb"], 2, 'spec').and_return([])
      post '/builds', :files => 'spec/models/car_spec.rb spec/models/car2_spec.rb spec/models/house_spec.rb spec/models/house2_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :server_type => 'rsync',
      :available_runner_usage => "50%"
    end
  
  end
  
  context "GET /builds/:id" do
    
    should 'return the build status' do
      build = Build.create(:done => false, :results => "testbot5\n..........\ncompleted")
      get "/builds/#{build[:id]}"
      assert_equal true, last_response.ok?
      assert_equal ({ "done" => false, "results" => "testbot5\n..........\ncompleted" }),
                   JSON.parse(last_response.body)
    end
    
    should 'remove a build that is done' do
      build = Build.create(:done => true)
      get "/builds/#{build[:id]}"
      assert_equal true, JSON.parse(last_response.body)['done']
      assert_equal 0, Build.count
    end
    
    should 'remove all related jobs of a build that is done' do
      build = Build.create(:done => true)
      related_job = Job.create(:build_id => build.id)
      other_job = Job.create(:build_id => nil)
      get "/builds/#{build[:id]}"
      assert !Job.find([ 'id = ?', related_job.id ])
      assert Job.find([ 'id = ?', other_job.id ])
    end
    
  end
  
  context "GET /jobs/next" do
  
    should "be able to return a job and mark it as taken" do
      job1 = Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => 'rsync', :requester_mac => "bb:bb:bb:bb:bb:bb", :project => 'things'
      
      get '/jobs/next', :version => Server.version
      assert last_response.ok?      
      
      assert_equal [ job1[:id], "bb:bb:bb:bb:bb:bb", "things", "server:/project", "spec", "rsync", "spec/models/car_spec.rb" ].join(','), last_response.body
      assert job1.reload[:taken_at] != nil
    end
  
    should "not return a job that has already been taken" do
      job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now, :type => 'spec'
      job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "aa:aa:aa:aa:aa:aa", :project => 'things'
      get '/jobs/next', :version => Server.version
      assert last_response.ok?
      assert_equal [ job2[:id], "aa:aa:aa:aa:aa:aa", "things", "server:/project", "spec", "rsync", "spec/models/house_spec.rb" ].join(','), last_response.body
      assert job2.reload[:taken_at] != nil
    end

    should "not return a job if there isnt any" do
      get '/jobs/next', :version => Server.version
      assert last_response.ok?
      assert_equal '', last_response.body
    end
    
    should "save which runner takes a job" do
      job = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "aa:aa:aa:aa:aa:aa"
      get '/jobs/next', :version => Server.version
      assert_equal Runner.first.id, job.reload.taken_by_id
    end
  
    should "save information about the runners" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini.local', :mac => "00:01:...", :idle_instances => 2, :max_instances => 4
      runner = DB[:runners].first
      assert_equal Server.version, runner[:version]
      assert_equal '127.0.0.1', runner[:ip]
      assert_equal 'macmini.local', runner[:hostname]
      assert_equal '00:01:...', runner[:mac]
      assert_equal 2, runner[:idle_instances]
      assert_equal 4, runner[:max_instances]
      assert (Time.now - 5) < runner[:last_seen_at]
      assert (Time.now + 5) > runner[:last_seen_at]
    end
  
    should "only create one record for the same mac" do
      get '/jobs/next', :version => Server.version, :mac => "00:01:..."
      get '/jobs/next', :version => Server.version, :mac => "00:01:..."
      assert_equal 1, Runner.count
    end
  
    should "not return anything to outdated clients" do
      Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project'
      get '/jobs/next', :version => "1", :mac => "00:..."
      assert last_response.ok?
      assert_equal '', last_response.body
    end
    
    should "only give jobs from the same source to a runner" do
      job1 = Job.create :files => 'spec/models/car_spec.rb', :type => 'spec', :requester_mac => "bb:bb:bb:bb:bb:bb"
      get '/jobs/next', :version => Server.version, :mac => "00:..."
      
      # Creating the second job here because of the random lookup.
      job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "aa:aa:aa:aa:aa:aa"
      get '/jobs/next', :version => Server.version, :mac => "00:...", :requester_mac => "bb:bb:bb:bb:bb:bb"
      
      assert last_response.ok?
      assert_equal '', last_response.body
    end
    
    should "return the jobs in random order in order to start working for a new requester right away" do
      20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "bb:bb:bb:bb:bb:bb" }
      
      20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "aa:aa:aa:aa:aa:aa" }
      
      macs = (0...10).map {
        get '/jobs/next', :version => Server.version, :mac => "00:..."
        last_response.body.split(',')[1]
      }
      
      assert macs.find { |mac| mac == 'bb:bb:bb:bb:bb:bb' }
      assert macs.find { |mac| mac == 'aa:aa:aa:aa:aa:aa' }
    end
    
    should "return the jobs randomly when passing requester" do
      20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "bb:bb:bb:bb:bb:bb" }
      
      20.times { Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "bb:bb:bb:bb:bb:bb" }
      
      files = (0...10).map {
        get '/jobs/next', :version => Server.version, :mac => "00:...", :requester_mac => "bb:bb:bb:bb:bb:bb"
        last_response.body.split(',').last
      }
      
      assert files.find { |file| file.include?('car') }
      assert files.find { |file| file.include?('house') }
    end
    
    should "return taken jobs to other runners if the runner hasn't been seen for 10 seconds or more" do
      missing_runner = Runner.create(:last_seen_at => Time.now - 15)
      old_taken_job = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :server_type => "rsync", :requester_mac => "aa:aa:aa:aa:aa:aa", :taken_by_id => missing_runner.id, :taken_at => Time.now - 30, :project => 'things'
      
      new_runner = Runner.create(:mac => "00:01")
      get '/jobs/next', :version => Server.version, :mac => "00:01"
      assert_equal new_runner.id, old_taken_job.reload.taken_by_id
      
      assert last_response.ok?
      assert_equal [ old_taken_job[:id], "aa:aa:aa:aa:aa:aa", "things", "server:/project", "spec", "rsync", "spec/models/house_spec.rb" ].join(','), last_response.body
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
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2, :username => 'user1'
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4, :username => 'user2'
      get '/runners/available'
      assert last_response.ok?
      assert_equal "127.0.0.1 macmini1.local 00:01 user1 2\n127.0.0.1 macmini2.local 00:02 user2 4", last_response.body
    end
    
    should "not return runners as available when not seen the last 10 seconds" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2, :username => "user1"
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 10)      
      get '/runners/available'
      assert_equal "127.0.0.1 macmini1.local 00:01 user1 2", last_response.body
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
        
    should "not return instances as available when not seen the last 10 seconds" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :idle_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :idle_instances => 4
      Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 10)
      get '/runners/available_instances'
      assert last_response.ok?
      assert_equal "2", last_response.body
    end
    
  end
  
  context "GET /runners/total_instances" do
    
    should "return the number of available runner instances" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :max_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :max_instances => 4
      get '/runners/total_instances'
      assert last_response.ok?
      assert_equal "6", last_response.body
    end    
        
    should "not return instances as available when not seen the last 10 seconds" do
      get '/jobs/next', :version => Server.version, :hostname => 'macmini1.local', :mac => "00:01", :max_instances => 2
      get '/jobs/next', :version => Server.version, :hostname => 'macmini2.local', :mac => "00:02", :max_instances => 4
      Runner.find(:mac => "00:02").update(:last_seen_at => Time.now - 10)
      get '/runners/total_instances'
      assert last_response.ok?
      assert_equal "2", last_response.body
    end
    
  end  
    
  context "GET /runners/ping" do
    
    should "update last_seen_at for the runner" do
      runner = Runner.create(:mac => 'aa:aa:aa:aa:aa:aa')
      get "/runners/ping", :mac => 'aa:aa:aa:aa:aa:aa', :version => Server.version
      runner.reload
      assert last_response.ok?
      assert (Time.now - 5) < runner[:last_seen_at]
      assert (Time.now + 5) > runner[:last_seen_at]
    end
    
    should "update data on the runner" do
      runner = Runner.create(:mac => 'aa:aa:..')
      get "/runners/ping", :mac => 'aa:aa:..', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Server.version, :username => 'jocke'
      runner.reload
      assert last_response.ok?
      assert_equal 'aa:aa:..', runner.mac
      assert_equal 4, runner.max_instances
      assert_equal 2, runner.idle_instances
      assert_equal 'hostname1', runner.hostname
      assert_equal Server.version, runner.version
      assert_equal 'jocke', runner.username
    end
    
    should "do nothing if the version does not match" do
      runner = Runner.create(:mac => 'aa:aa:..', :version => Server.version)
      get "/runners/ping", :mac => 'aa:aa:..', :version => Server.version - 1
      assert last_response.ok?
      assert_equal Server.version, runner.reload.version
    end
    
    should "do nothing if the runners isnt known yet found" do
      get "/runners/ping", :mac => 'aa:aa:aa:aa:aa:aa', :version => Server.version
      assert last_response.ok?
    end
    
  end
  
  context "PUT /jobs/:id" do

    should "receive the results of a job" do
      job = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30
      put "/jobs/#{job[:id]}", :result => 'test run result'
      assert last_response.ok?
      assert_equal 'test run result', job.reload.result
    end

    should "update the related build" do
      build = Build.create
      job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build_id => build[:id]
      job2 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build_id => build[:id]      
      put "/jobs/#{job1[:id]}", :result => 'test run result 1\n'
      put "/jobs/#{job2[:id]}", :result => 'test run result 2\n'
      assert_equal 'test run result 1\ntest run result 2\n', build.reload[:results]
    end
    
    should "make the related build done if there are no more jobs for the build" do
      build = Build.create
      job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build_id => build[:id]
      job2 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build_id => build[:id]
      put "/jobs/#{job1[:id]}", :result => 'test run result 1\n'
      put "/jobs/#{job2[:id]}", :result => 'test run result 2\n'
      assert_equal true, build.reload[:done]
    end
    
    # should "store the runtime results" do
    #   build = Build.create
    #   job1 = Job.create :files => 'spec/models/car_spec.rb spec/models/house_spec.rb', :taken_at => Time.now - 30, :build_id => build[:id], :taken_at => Time.now - 30, :type => 'spec'
    #   put "/jobs/#{job1[:id]}", :result => 'test run result 1\n'
    #         
    #   assert (13...16).include?(Runtime.find(:path => "spec/models/car_spec.rb", :type => "spec").time)
    #   assert (13...16).include?(Runtime.find(:path => "spec/models/house_spec.rb", :type => "spec").time)
    # end

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
