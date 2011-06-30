require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/server/server'))
require 'test/unit'
require 'rack/test'
require 'shoulda'
require 'flexmock/test_unit'

set :environment, :test

module Testbot::Server

  class ServerTest < Test::Unit::TestCase
    include Rack::Test::Methods

    def setup
      Job.delete_all
      Runner.delete_all
      Build.delete_all
    end

    def app
      Sinatra::Application
    end

    context "POST /builds" do

      should "create a build and return its id" do
        flexmock(Runner).should_receive(:total_instances).and_return(2)
        post '/builds', :files => 'spec/models/car_spec.rb spec/models/house_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :available_runner_usage => "100%", :project => 'things', :sizes => "10 20", :jruby => false

        first_build = Build.all.first
        assert last_response.ok?

        assert_equal first_build.id.to_s, last_response.body
        assert_equal 'spec/models/car_spec.rb spec/models/house_spec.rb', first_build.files
        assert_equal '10 20', first_build.sizes
        assert_equal 'server:/path/to/project', first_build.root
        assert_equal 'spec', first_build.type
        assert_equal 'things', first_build.project
        assert_equal 0, first_build.jruby
        assert_equal '', first_build.results
        assert_equal true, first_build.success
      end

      should "create jobs from the build based on the number of total instances" do
        flexmock(Runner).should_receive(:total_instances).and_return(2)      
        flexmock(Group).should_receive(:build).with(["spec/models/car_spec.rb", "spec/models/car2_spec.rb", "spec/models/house_spec.rb", "spec/models/house2_spec.rb"], [ 1, 1, 1, 1 ], 2, 'spec').once.and_return([
                                                                                                                                                                                                                   ["spec/models/car_spec.rb", "spec/models/car2_spec.rb"],
                                                                                                                                                                                                                   ["spec/models/house_spec.rb", "spec/models/house2_spec.rb"]
        ])

        post '/builds', :files => 'spec/models/car_spec.rb spec/models/car2_spec.rb spec/models/house_spec.rb spec/models/house2_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :available_runner_usage => "100%", :project => 'things', :sizes => "1 1 1 1", :jruby => true

        assert_equal 2, Job.count
        first_job, last_job = Job.all
        assert_equal 'spec/models/car_spec.rb spec/models/car2_spec.rb', first_job.files
        assert_equal 'spec/models/house_spec.rb spec/models/house2_spec.rb', last_job.files

        assert_equal 'server:/path/to/project', first_job.root
        assert_equal 'spec', first_job.type
        assert_equal 'things', first_job.project
        assert_equal 1, first_job.jruby
        assert_equal Build.all.first, first_job.build
      end

      should "only use resources according to available_runner_usage" do
        flexmock(Runner).should_receive(:total_instances).and_return(4)
        flexmock(Group).should_receive(:build).with(["spec/models/car_spec.rb", "spec/models/car2_spec.rb", "spec/models/house_spec.rb", "spec/models/house2_spec.rb"], [ 1, 1, 1, 1 ], 2, 'spec').and_return([])
        post '/builds', :files => 'spec/models/car_spec.rb spec/models/car2_spec.rb spec/models/house_spec.rb spec/models/house2_spec.rb', :root => 'server:/path/to/project', :type => 'spec', :sizes => "1 1 1 1", :available_runner_usage => "50%"
      end

    end

    context "GET /builds/:id" do

      should 'return the build status' do
        build = Build.create(:done => false, :results => "testbot5\n..........\ncompleted", :success => false)
        get "/builds/#{build.id}"
        assert_equal true, last_response.ok?
        assert_equal ({ "done" => false, "results" => "testbot5\n..........\ncompleted", "success" => false }),
          JSON.parse(last_response.body)
      end

      should 'remove a build that is done' do
        build = Build.create(:done => true)
        get "/builds/#{build.id}"
        assert_equal true, JSON.parse(last_response.body)['done']
        assert_equal 0, Build.count
      end

      should 'remove all related jobs of a build that is done' do
        build = Build.create(:done => true)
        related_job = Job.create(:build => build)
        other_job = Job.create(:build => nil)
        get "/builds/#{build.id}"
        assert !Job.find(related_job.id)
        assert Job.find(other_job.id)
      end

    end

    context "GET /jobs/next" do

      should "be able to return a job and mark it as taken" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project', :type => 'spec', :build => build, :project => 'things', :jruby => 1

        get '/jobs/next', :version => Testbot.version
        assert last_response.ok?      

        assert_equal [ job1.id, build.id, "things", "server:/project", "spec", "jruby", "spec/models/car_spec.rb" ].join(','), last_response.body
        assert job1.taken_at != nil
      end

      should "not return a job that has already been taken" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now, :type => 'spec', :build => build
        job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build, :project => 'things', :jruby => 0
        get '/jobs/next', :version => Testbot.version
        assert last_response.ok?
        assert_equal [ job2.id, build.id, "things", "server:/project", "spec", "ruby", "spec/models/house_spec.rb" ].join(','), last_response.body
        assert job2.taken_at != nil
      end

      should "not return a job if there isnt any" do
        get '/jobs/next', :version => Testbot.version
        assert last_response.ok?
        assert_equal '', last_response.body
      end

      should "save which runner takes a job" do
        job = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => Build.create
        get '/jobs/next', :version => Testbot.version
        assert_equal Runner.first, job.taken_by
      end

      should "save information about the runners" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini.local', :uid => "00:01:...", :idle_instances => 2, :max_instances => 4
        runner = Runner.first
        assert_equal Testbot.version, runner.version
        assert_equal '127.0.0.1', runner.ip
        assert_equal 'macmini.local', runner.hostname
        assert_equal '00:01:...', runner.uid
        assert_equal 2, runner.idle_instances
        assert_equal 4, runner.max_instances
        assert (Time.now - 5) < runner.last_seen_at
        assert (Time.now + 5) > runner.last_seen_at
      end

      should "only create one record for the same mac" do
        get '/jobs/next', :version => Testbot.version, :uid => "00:01:..."
        get '/jobs/next', :version => Testbot.version, :uid => "00:01:..."
        assert_equal 1, Runner.count
      end

      should "not return anything to outdated clients" do
        Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project'
        get '/jobs/next', :version => "1", :uid => "00:..."
        assert last_response.ok?
        assert_equal '', last_response.body
      end

      should "only give jobs from the same source to a runner" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :type => 'spec', :build => build
        get '/jobs/next', :version => Testbot.version, :uid => "00:...", :build_id => build.id

        # Creating the second job here because of the random lookup.
        job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build
        get '/jobs/next', :version => Testbot.version, :uid => "00:...", :build_id => build.id + 1

        assert last_response.ok?
        assert_equal '', last_response.body
      end

      should "not give more jruby jobs to an instance that can't take more" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :type => 'spec', :jruby => 1, :build => build
        get '/jobs/next', :version => Testbot.version, :uid => "00:..."

        # Creating the second job here because of the random lookup.
        job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :jruby => 1, :build => build
        get '/jobs/next', :version => Testbot.version, :uid => "00:...", :no_jruby => "true"

        assert last_response.ok?
        assert_equal '', last_response.body
      end

      should "still return other jobs when the runner cant take more jruby jobs" do
        job1 = Job.create :files => 'spec/models/car_spec.rb', :type => 'spec', :jruby => 1, :build => Build.create
        get '/jobs/next', :version => Testbot.version, :uid => "00:..."

        # Creating the second job here because of the random lookup.
        job2 = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :jruby => 0, :build => Build.create
        get '/jobs/next', :version => Testbot.version, :uid => "00:...", :no_jruby => "true"

        assert last_response.ok?
        assert_equal job2.id.to_s, last_response.body.split(',')[0]
      end

      should "return the jobs in random order in order to start working for a new build right away" do
        build1, build2 = Build.create, Build.create
        20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build1 }

        20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build2 }

        build_ids = (0...10).map {
          get '/jobs/next', :version => Testbot.version, :uid => "00:..."
          last_response.body.split(',')[1]
        }

        assert build_ids.find { |build_id| build_id == build1.id.to_s }
        assert build_ids.find { |build_id| build_id == build2.id.to_s }
      end

      should "return the jobs randomly when passing build_id" do
        build = Build.create
        20.times { Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build }

        20.times { Job.create :files => 'spec/models/car_spec.rb', :root => 'server:/project', :type => 'spec', :build => build }

        files = (0...10).map {
          get '/jobs/next', :version => Testbot.version, :uid => "00:...", :build_id => build.id
          last_response.body.split(',').last
        }

        assert files.find { |file| file.include?('car') }
        assert files.find { |file| file.include?('house') }
      end

      should "return taken jobs to other runners if the runner hasn't been seen for 10 seconds or more" do
        missing_runner = Runner.create(:last_seen_at => Time.now - 15)
        build = Build.create
        old_taken_job = Job.create :files => 'spec/models/house_spec.rb', :root => 'server:/project', :type => 'spec', :build => build, :taken_by => missing_runner, :taken_at => Time.now - 30, :project => 'things'

        new_runner = Runner.create(:uid => "00:01")
        get '/jobs/next', :version => Testbot.version, :uid => "00:01"
        assert_equal new_runner, old_taken_job.taken_by

        assert last_response.ok?
        assert_equal [ old_taken_job.id, build.id.to_s, "things", "server:/project", "spec", "ruby", "spec/models/house_spec.rb" ].join(','), last_response.body
      end

    end

    context "/runners/outdated" do

      should "return a list of outdated runners" do
        get '/jobs/next', :version => "1", :hostname => 'macmini1.local', :uid => "00:01"
        get '/jobs/next', :version => "1", :hostname => 'macmini2.local', :uid => "00:02"
        get '/jobs/next'    
        get '/jobs/next', :version => Testbot.version.to_s, :hostname => 'macmini3.local', :uid => "00:03"
        assert_equal 4, Runner.count
        get '/runners/outdated'
        assert last_response.ok?
        assert_equal "127.0.0.1 macmini1.local 00:01\n127.0.0.1 macmini2.local 00:02\n127.0.0.1", last_response.body
      end

    end

    context "GET /runners/available_runners" do

      should "return a list of available runners" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :idle_instances => 2, :username => 'user1'
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :idle_instances => 4, :username => 'user2'
        get '/runners/available'
        assert last_response.ok?
        assert_equal "127.0.0.1 macmini1.local 00:01 user1 2\n127.0.0.1 macmini2.local 00:02 user2 4", last_response.body
      end

      should "not return runners as available when not seen the last 10 seconds" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :idle_instances => 2, :username => "user1"
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :idle_instances => 4
        Runner.find_by_uid("00:02").update(:last_seen_at => Time.now - 10)      
        get '/runners/available'
        assert_equal "127.0.0.1 macmini1.local 00:01 user1 2", last_response.body
      end

    end

    context "GET /runners/available_instances" do

      should "return the number of available runner instances" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :idle_instances => 2
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :idle_instances => 4
        get '/runners/available_instances'
        assert last_response.ok?
        assert_equal "6", last_response.body
      end    

      should "not return instances as available when not seen the last 10 seconds" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :idle_instances => 2
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :idle_instances => 4
        Runner.find_by_uid("00:02").update(:last_seen_at => Time.now - 10)
        get '/runners/available_instances'
        assert last_response.ok?
        assert_equal "2", last_response.body
      end

    end

    context "GET /runners/total_instances" do

      should "return the number of available runner instances" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :max_instances => 2
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :max_instances => 4
        get '/runners/total_instances'
        assert last_response.ok?
        assert_equal "6", last_response.body
      end    

      should "not return instances as available when not seen the last 10 seconds" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :max_instances => 2
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :max_instances => 4
        Runner.find_by_uid("00:02").update(:last_seen_at => Time.now - 10)
        get '/runners/total_instances'
        assert last_response.ok?
        assert_equal "2", last_response.body
      end

    end  

    context "GET /runners/ping" do

      should "update last_seen_at for the runner" do
        runner = Runner.create(:uid => 'aa:aa:aa:aa:aa:aa')
        get "/runners/ping", :uid => 'aa:aa:aa:aa:aa:aa', :version => Testbot.version
        assert last_response.ok?
        assert (Time.now - 5) < runner.last_seen_at
        assert (Time.now + 5) > runner.last_seen_at
      end

      should "update data on the runner" do
        build = Build.create
        runner = Runner.create(:uid => 'aa:aa:..')
        get "/runners/ping", :uid => 'aa:aa:..', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Testbot.version, :username => 'jocke', :build_id => build.id
        assert last_response.ok?
        assert_equal 'aa:aa:..', runner.uid
        assert_equal 4, runner.max_instances
        assert_equal 2, runner.idle_instances
        assert_equal 'hostname1', runner.hostname
        assert_equal Testbot.version, runner.version
        assert_equal 'jocke', runner.username
        assert_equal build, runner.build
      end

      should "do nothing if the version does not match" do
        runner = Runner.create(:uid => 'aa:aa:..', :version => Testbot.version)
        get "/runners/ping", :uid => 'aa:aa:..', :version => "OLD"
        assert last_response.ok?
        assert_equal Testbot.version, runner.version
      end

      should "do nothing if the runners isnt known yet found" do
        get "/runners/ping", :uid => 'aa:aa:aa:aa:aa:aa', :version => Testbot.version
        assert last_response.ok?
      end

      should "return an order to stop the build if the build id does not exist anymore" do
        runner = Runner.create(:uid => 'aa:aa:..')
        get "/runners/ping", :uid => 'aa:aa:..', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Testbot.version, :username => 'jocke', :build_id => 1
        assert_equal last_response.body, "stop_build,1"
      end

      should "not return an order to stop a build without an id" do
        runner = Runner.create(:uid => 'aa:aa:..')
        get "/runners/ping", :uid => 'aa:aa:..', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Testbot.version, :username => 'jocke', :build_id => ''
        assert_equal last_response.body, ''
        get "/runners/ping", :uid => 'aa:aa:..', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Testbot.version, :username => 'jocke', :build_id => nil
        assert_equal last_response.body, ''
      end

    end

    context "PUT /jobs/:id" do

      should "receive the results of a job" do
        job = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30
        put "/jobs/#{job.id}", :result => 'test run result', :success => true
        assert last_response.ok?
        assert_equal 'test run result', job.result
        assert_equal 'true', job.success
      end

      should "update the related build" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build => build
        job2 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build => build      
        put "/jobs/#{job1.id}", :result => 'test run result 1\n', :success => "true"
        put "/jobs/#{job2.id}", :result => 'test run result 2\n', :success => "true"
        assert_equal 'test run result 1\ntest run result 2\n', build.results
        assert_equal true, build.success
      end

      should "make the related build done if there are no more jobs for the build" do
        build = Build.create :files => 'spec/models/car_spec.rb spec/models/house_spec.rb'
        job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build => build
        job2 = Job.create :files => 'spec/models/house_spec.rb', :taken_at => Time.now - 30, :build => build
        put "/jobs/#{job1.id}", :result => 'test run result 1\n', :success => true
        put "/jobs/#{job2.id}", :result => 'test run result 2\n', :success => true
        assert_equal true, build.done
      end

      should "make the build fail if one of the jobs fail" do
        build = Build.create
        job1 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build => build
        job2 = Job.create :files => 'spec/models/car_spec.rb', :taken_at => Time.now - 30, :build => build
        put "/jobs/#{job1.id}", :result => 'test run result 1\n', :success => false
        put "/jobs/#{job2.id}", :result => 'test run result 2\n', :success => true
        assert_equal false, build.success
      end 

    end

    context "GET /version" do

      should "return its version" do
        get '/version'
        assert last_response.ok?
        assert_equal Testbot.version.to_s, last_response.body
      end

    end

    context "GET /runners" do

      should "return runner information in json format" do
        get '/jobs/next', :version => Testbot.version, :uid => "00:01"
        get "/runners/ping", :uid => '00:01', :max_instances => 4, :idle_instances => 2, :hostname => "hostname1", :version => Testbot.version, :username => 'testbot', :build_id => nil
        get '/runners'
        
        assert last_response.ok?
        assert_equal ([ { "version" => Testbot.version.to_s, "build" => nil, "hostname" => 'hostname1', "uid" => "00:01",
                          "idle_instances" => 2, "max_instances" => 4, "username" => 'testbot',
                          "ip" => "127.0.0.1", "last_seen_at" => Runner.first.last_seen_at.to_s } ]),
                     JSON.parse(last_response.body)
      end

      should "not return instances when not seen the last 10 seconds" do
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini1.local', :uid => "00:01", :idle_instances => 2
        get '/jobs/next', :version => Testbot.version, :hostname => 'macmini2.local', :uid => "00:02", :idle_instances => 4
        Runner.find_by_uid("00:02").update(:last_seen_at => Time.now - 10)
        get '/runners'
        assert last_response.ok?
        parsed_body = JSON.parse(last_response.body)
        assert_equal 1, parsed_body.size
        assert_equal '00:01', parsed_body.first["uid"] 
      end

    end

    context "GET /status" do

      should "return the contents of the status page" do
        get '/status'
        assert_equal true, last_response.body.include?('Testbot status')
      end

    end

    context "GET /status/:dir/:file" do

      should "return the file" do
        get "/status/javascripts/jquery-1.4.4.min.js"
        assert_equal true, last_response.body.include?('jQuery JavaScript Library v1.4.4')
      end

    end

  end

end

