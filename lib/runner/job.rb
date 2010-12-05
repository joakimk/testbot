class Job
  attr_reader :root, :project, :requester_mac
    
  def initialize(runner, id, requester_mac, project, root, type, ruby_interpreter, files)
    @runner, @id, @requester_mac, @project, @root, @type, @ruby_interpreter, @files =
         runner, id, requester_mac, project, root, type, ruby_interpreter, files
  end
  
  def jruby?
    @ruby_interpreter == 'jruby'
  end
  
  def run(instance)
    puts "Running job #{@id} from #{@requester_mac}... "
    test_env_number = (instance == 0) ? '' : instance + 1
    result = "\n#{`hostname`.chomp}:#{Dir.pwd}\n"
    base_environment = "export RAILS_ENV=test; export TEST_ENV_NUMBER=#{test_env_number}; cd #{@project};"
    
    adapter = Adapter.find(@type)
    result += `#{base_environment} #{adapter.command(@project, ruby_cmd, @files)} 2>&1`

    Server.put("/jobs/#{@id}", :body => { :result => result, :success => ($?.exitstatus == 0) })
    puts "Job #{@id} finished."
  end
  
  private
  
  def ruby_cmd
    if @ruby_interpreter == 'jruby' && @runner.config.jruby_opts
      'jruby ' + @runner.config.jruby_opts
    else
      @ruby_interpreter
    end
  end
end

