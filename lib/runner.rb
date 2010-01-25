require 'rubygems'
require 'httparty'
require 'macaddr'
require 'ostruct'

TESTBOT_VERSION = 5
TIME_BETWEEN_POLLS = 1
TIME_BETWEEN_VERSION_CHECKS = 60

@@config = OpenStruct.new(ENV['INTEGRATION_TEST'] ?
           { :server_uri => "http://localhost:2288", :automatic_updates => false, :max_instances => 1 } :
           YAML.load_file("#{ENV['HOME']}/.testbot_runner.yml"))

class Job
  def initialize(id, root, specs)
    @id, @root, @specs = id, root, specs
  end
  
  def run(instance)
    puts "Running job #{@id} in instance #{instance}... "
    system "rsync -az --delete -e ssh #{@root}/ instance#{instance}"
    test_env_number = (instance == 0) ? '' : instance + 1
    result = `export RAILS_ENV=test; export TEST_ENV_NUMBER=#{test_env_number}; export RSPEC_COLOR=true; cd instance#{instance}; rake testbot:before_run; script/spec -O spec/spec.opts #{@specs}`
    Server.put("/jobs/#{@id}", :body => { :result => result })
    puts "Job #{@id} finished."
  end
end

class Server
  include HTTParty
  base_uri @@config.server_uri
end

class Runner
    
  def initialize
    @instances = []
    @last_version_check = Time.now - TIME_BETWEEN_VERSION_CHECKS - 1    
  end
  
  def run!
    loop do      
      sleep TIME_BETWEEN_POLLS
      check_for_update if time_for_update?
      clear_completed_instances # Makes sure all instances are listed as available after a run
      next_job = Server.get("/jobs/next", :query => query_params) rescue nil
      next if next_job == nil
      @instances << [ Thread.new { Job.new(*next_job.split(',')).run(free_instance_number) },
                      free_instance_number ]
      loop do
        clear_completed_instances
        break unless max_instances_running?
      end
    end
  end
    
  private
  
  def time_for_update?
    time_for_update = ((Time.now - @last_version_check) >= TIME_BETWEEN_VERSION_CHECKS)
    @last_version_check = Time.now if time_for_update
    time_for_update
  end
  
  def check_for_update
    return unless @@config.automatic_updates
    version = Server.get('/version') rescue TESTBOT_VERSION
    return unless version.to_i != TESTBOT_VERSION
    
    update_uri = Server.get("/update_uri") rescue nil
    if update_uri
      successful_download = system "rm -rf ~/runner_update && mkdir ~/runner_update && curl -L #{update_uri} | tar xz --strip 1 -C ~/runner_update"

      # This closes the process and runs the updater.
      exec "~/runner_update/bin/update_runner" if successful_download
    end
  end
  
  def query_params
    { :version => TESTBOT_VERSION, :mac => Mac.addr, :hostname => (@hostname ||= `hostname`.chomp),
      :idle_instances => (@@config.max_instances - @instances.size) }
  end
  
  def max_instances_running?
    @instances.size == @@config.max_instances
  end

  def clear_completed_instances
    @instances.each_with_index do |data, index|
      @instances.delete_at(index) if data.first.join(0.25)
    end
  end

  def free_instance_number
    0.upto(@@config.max_instances - 1) do |number|
      return number unless @instances.find { |instance, n| n == number }
    end
  end
   
end

runner = Runner.new
runner.run!
