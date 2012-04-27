require File.expand_path(File.join(File.dirname(__FILE__), 'runner.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'safe_result_text.rb'))

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

      Server.put("/jobs/#{@id}", :body => { :result => SafeResultText.clean(result), :status => status, :time => run_time })
      puts "Job #{@id} finished."
    end

    def kill!(build_id)
      if @build_id == build_id && @test_process
        # The child process that runs the tests is a shell, we need to kill it's child process
        system("pkill -KILL -P #{@test_process.pid}")
        @killed = true
      end
    end

    private

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
    end

    def run_and_return_result(command)
      @test_process = open("|#{command} 2>&1", 'r')
      output = ""
      t = Time.now
      while char = @test_process.getc
        char = (char.is_a?(Fixnum) ? char.chr : char) # 1.8 <-> 1.9
        output << char
        if Time.now - t > 0.5
          post_results(output)
          t = Time.now
        end
      end
      @test_process.close
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
