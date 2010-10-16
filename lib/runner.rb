require 'rubygems'
require 'httparty'
require 'macaddr'
require 'ostruct'

TESTBOT_VERSION = 20
TIME_BETWEEN_POLLS = 1
TIME_BETWEEN_VERSION_CHECKS = 60
MAX_CPU_USAGE_WHEN_IDLE = 50

@@config = OpenStruct.new(ENV['INTEGRATION_TEST'] ?
           { :server_uri => "http://localhost:22880", :automatic_updates => false, :max_instances => 1 } :
           YAML.load_file("#{ENV['HOME']}/.testbot_runner.yml"))

class CpuUsage

 def self.current
   process_usages = `ps -eo pcpu`
   total_usage = process_usages.split("\n").inject(0) { |sum, usage| sum += usage.strip.to_f }
   (total_usage / number_of_cpus).to_i
 end

 private

 def self.number_of_cpus
   case RUBY_PLATFORM
     when /darwin/
       `hwprefs cpu_count`.to_i
     when /linux/
       `cat /proc/cpuinfo | grep processor | wc -l`.to_i
   end
 end

end

class Job

  attr_reader :server_type, :root, :requester_ip
  
  def initialize(id, requester_ip, root, type, server_type, files)
    @id, @requester_ip, @root, @type, @server_type, @files = id, requester_ip, root, type, server_type, files
  end
  
  def run(instance)
    puts "Running job #{@id} from #{@requester_ip} (#{@server_type})... "
    test_env_number = (instance == 0) ? '' : instance + 1
    result = "\n#{`hostname`.chomp}:#{Dir.pwd}\n"
    base_environment = "export RAILS_ENV=test; export TEST_ENV_NUMBER=#{test_env_number}; cd instance_#{@server_type};"
    
    if @type == 'rspec'
      result += `#{base_environment} export RSPEC_COLOR=true; script/spec -O spec/spec.opts #{@files}  2>&1`
    elsif @type == 'cucumber'
      result += `#{base_environment} export AUTOTEST=1; script/cucumber -f progress --backtrace -r features/support -r features/step_definitions #{@files} -t ~@disabled_in_cruise 2>&1`
    else
      raise "Unknown job type! (#{@type})"
    end
    
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
    @last_requester_ip = nil
    @last_version_check = Time.now - TIME_BETWEEN_VERSION_CHECKS - 1    
  end
  
  def run!
    loop do
      sleep TIME_BETWEEN_POLLS
      check_for_update if time_for_update?

      # Only get jobs from one requester at a time
      if @instances.size > 0
        params = "?requester_ip=#{@last_requester_ip}"
      else
        params = ''
        @last_requester_ip = nil
      end
      
      # Makes sure all instances are listed as available after a run
      clear_completed_instances 
      next unless cpu_available?
      
      next_job = Server.get("/jobs/next#{params}", :query => query_params) rescue nil
      next if next_job == nil
      
      job = Job.new(*next_job.split(','))
      if first_job_from_requester?
        fetch_code(job)
        before_run(job)
      end
      
      @instances << [ Thread.new { job.run(free_instance_number) },
                      free_instance_number ]
      @last_requester_ip = job.requester_ip
      loop do
        clear_completed_instances
        break unless max_instances_running?
      end
    end
  end
      
  private
  
  def fetch_code(job)
    if job.server_type == 'rsync'
      system "rsync -az --delete -e ssh #{job.root}/ instance_rsync"
    elsif job.server_type == 'git'
      if File.exists?("instance_git")
        system "cd instance_git; git pull; cd .."
      else
        system "git clone #{job.root} instance_git"
      end
    else
      raise "Unknown root type! (#{job.server_type})"
    end
  end
  
  def before_run(job)
    system "export RAILS_ENV=test; export TEST_INSTANCES=#{@@config.max_instances}; export TEST_SERVER_TYPE=#{job.server_type}; cd instance_#{job.server_type}; rake testbot:before_run"
  end
  
  def first_job_from_requester?
    @last_requester_ip == nil
  end
  
  def cpu_available?
    @instances.size > 0 || CpuUsage.current < MAX_CPU_USAGE_WHEN_IDLE
  end
  
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

# Remove legacy instanceX style folders
Dir.entries(".").find_all { |name| name.include?('instance') && ( name[-1,1] == '0' || name[-1,1].to_i != 0) }.each { |folder|
  system "rm -rf #{folder}"
}

runner = Runner.new
runner.run!
