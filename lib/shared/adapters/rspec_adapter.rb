require File.expand_path(File.join(File.dirname(__FILE__), "/helpers/ruby_env"))
require File.expand_path(File.join(File.dirname(__FILE__), "../color"))

class RspecAdapter
  
  def self.command(project_path, ruby_interpreter, files)
    spec_command = RubyEnv.ruby_command(project_path, :script => "script/spec", :bin => "rspec",
                                                      :ruby_interpreter => ruby_interpreter)
    if File.exists?("#{project_path}/spec/spec.opts")
      spec_command += " -O spec/spec.opts"
    end

    "export RSPEC_COLOR=true; #{spec_command} #{files}"
  end
  
  def self.test_files(dir)
    Dir["#{dir}/#{file_pattern}"]
  end

  def self.get_sizes(files)
    files.map { |file| File.stat(file).size }
  end
  
  def self.requester_port
    2299
  end
  
  def self.pluralized
    'specs'
  end
  
  def self.base_path
    type
  end
  
  def self.name
    'RSpec'
  end
  
  def self.type
    'spec'
  end

  # This is an optional method. It gets passed the entire test result and summarizes it. See the tests.
  def self.sum_results(results)
    examples, failures, pending = 0, 0, 0
    results.split("\n").each do |line|
      line =~ /(\d+) examples?, (\d+) failures?(, (\d+) pending)?/
      next unless $1
      examples += $1.to_i
      failures += $2.to_i
      pending += $4.to_i
    end

    result = [ pluralize(examples, 'example'), pluralize(failures, 'failure'), (pending > 0 ? "#{pending} pending" : nil) ].compact.join(', ')
    if failures == 0 && pending == 0
      Color.colorize(result, :green)
    elsif failures == 0 && pending > 0
      Color.colorize(result, :orange)
    else
      Color.colorize(result, :red)
    end
  end

private

  def self.pluralize(count, singular)
    if count == 1
      "#{count} #{singular}"
    else
      "#{count} #{singular}s"
    end
  end

  def self.file_pattern
    '**/**/*_spec.rb'
  end
    
end
