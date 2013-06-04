require File.expand_path(File.join(File.dirname(__FILE__), 'runner.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'safe_result_text.rb'))
require 'posix/spawn'

module Testbot::Runner
  class Job
    attr_reader :root, :project, :build_id

    TIME_TO_WAIT_BETWEEN_POSTING_RESULTS = 5

    def initialize(runner, id, build_id, project, root, type, ruby_interpreter, files)
      @runner, @id, @build_id, @project, @root, @type, @ruby_interpreter, @files =
        runner, id, build_id, project, root, type, ruby_interpreter, files
      @success = true
    end

    def jruby?
      @ruby_interpreter == 'jruby'
    end

    def run(instance)
      return if @killed
      puts "Running job #{@id} (build #{@build_id})... "
      test_env_number = (instance == 0) ? '' : instance + 1
      result = "\n#{`hostname`.chomp}:#{Dir.pwd}\n"
      base_environment = "export RAILS_ENV=test; export TEST_ENV_NUMBER=#{test_env_number}; cd #{@project};"

      adapter = Adapter.find(@type)
      run_time = measure_run_time do
        result += run_and_return_result("#{base_environment} #{adapter.command(@project, ruby_cmd, @files)}")
      end

      Server.put("/jobs/#{@id}", :body => { :result => SafeResultText.clean(result), :status => status, :time => run_time })
      puts "Job #{@id} finished."
    end

    def kill!(build_id)
      if @build_id == build_id && @pid
        kill_processes
        @killed = true
      end
    end

    private

    def kill_processes
      # Kill process and its children (processes in the same group)
      Process.kill('KILL', -@pid) rescue :failed_to_kill_process
    end

    def status
      success? ? "successful" : "failed"
    end

    def measure_run_time
      start_time = Time.now
      yield
      (Time.now - start_time) * 100
    end

    def post_results(output)
      Server.put("/jobs/#{@id}", :body => { :result => SafeResultText.clean(output), :status => "building" })
    rescue Timeout::Error
      puts "Got a timeout when posting an job result update. This can happen when the server is busy and is not a critical error."
    end

    def run_and_return_result(command)
      read_pipe = spawn_process(command)

      output = ""
      last_post_time = Time.now
      while char = read_pipe.getc
        char = (char.is_a?(Fixnum) ? char.chr : char) # 1.8 <-> 1.9
        output << char
        if Time.now - last_post_time > TIME_TO_WAIT_BETWEEN_POSTING_RESULTS
          post_results(output)
          last_post_time = Time.now
        end
      end

      # Kill child processes, if any
      kill_processes

      output
    end

    def spawn_process(command)
      read_pipe, write_pipe = IO.pipe
      @pid = POSIX::Spawn::spawn(command, :err => write_pipe, :out => write_pipe, :pgroup => true)

      Thread.new do
        Process.waitpid(@pid)
        @success = ($?.exitstatus == 0)
        write_pipe.close
      end

      read_pipe
    end

    def success?
      @success
    end

    def ruby_cmd
      if @ruby_interpreter == 'jruby' && @runner.config.jruby_opts
        'jruby ' + @runner.config.jruby_opts
      else
        @ruby_interpreter
      end
    end
  end
end
