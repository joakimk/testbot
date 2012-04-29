require File.expand_path(File.join(File.dirname(__FILE__), 'runner.rb'))

module Testbot::Runner
  class Job
    attr_reader :root, :project, :build_id

    def initialize(runner, id, build_id, project, root, type, ruby_interpreter, files)
      @runner, @id, @build_id, @project, @root, @type, @ruby_interpreter, @files =
        runner, id, build_id, project, root, type, ruby_interpreter, files
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

      Server.put("/jobs/#{@id}", :body => { :result => result, :success => success?, :time => run_time })
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

    def measure_run_time
      start_time = Time.now
      yield
      (Time.now - start_time) * 100
    end

    def run_and_return_result(command)
      r, w = IO.pipe
      @pid = spawn(command, err: w, out: w, pgroup: true)
      Process.wait(@pid)
      w.close
      output = r.read

      # Kill child processes, if any
      kill_processes

      output
    end

    def success?
      $?.exitstatus == 0
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
