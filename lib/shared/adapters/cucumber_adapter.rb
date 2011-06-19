require File.expand_path(File.join(File.dirname(__FILE__), "/helpers/ruby_env"))
require File.expand_path(File.join(File.dirname(__FILE__), "../color"))

class CucumberAdapter
  
  def self.command(project_path, ruby_interpreter, files)
    cucumber_command = RubyEnv.ruby_command(project_path, :script => "script/cucumber", :bin => "cucumber",
                                                          :ruby_interpreter => ruby_interpreter)
    "export AUTOTEST=1; #{cucumber_command} -f progress --backtrace -r features/support -r features/step_definitions #{files} -t ~@disabled"
  end
 
  def self.test_files(dir)
    Dir["#{dir}/#{file_pattern}"]
  end
  
  def self.get_sizes(files)
    files.map { |file| File.stat(file).size }
  end

  def self.requester_port
    2230
  end
  
  def self.pluralized
    'features'
  end
  
  def self.base_path
    pluralized
  end
  
  def self.name
    'Cucumber'
  end
  
  def self.type
    pluralized
  end

  # This is an optional method. It gets passed the entire test result and summarizes it. See the tests.
  def self.sum_results(text)
    scenarios, steps = parse_scenarios_and_steps(text)

    scenarios_line = "#{scenarios[:total]} scenarios (" + [
      (Color.colorize("#{scenarios[:failed]} failed", :red) if scenarios[:failed] > 0),
      (Color.colorize("#{scenarios[:undefined]} undefined", :orange) if scenarios[:undefined] > 0),
      (Color.colorize("#{scenarios[:passed]} passed", :green) if scenarios[:passed] > 0)
    ].compact.join(', ') + ")"

    steps_line = "#{steps[:total]} steps (" + [
      (Color.colorize("#{steps[:failed]} failed", :red) if steps[:failed] > 0),
      (Color.colorize("#{steps[:skipped]} skipped", :cyan) if steps[:skipped] > 0),
      (Color.colorize("#{steps[:undefined]} undefined", :orange) if steps[:undefined] > 0),
      (Color.colorize("#{steps[:passed]} passed", :green) if steps[:passed] > 0)
    ].compact.join(', ') + ")"

    scenarios_line + "\n" + steps_line
  end

private

  def self.parse_scenarios_and_steps(text)
    results = {
      :scenarios => { :total => 0, :passed => 0, :failed => 0, :undefined => 0 },
      :steps => { :total => 0, :passed => 0, :failed => 0, :skipped => 0, :undefined => 0 }
    }

    Color.strip(text).split("\n").each do |line|
      type = line.include?("scenarios") ? :scenarios : :steps
        
      if match = line.match(/\((.+)\)/)
        results[type][:total] += line.split.first.to_i
        parse_status_counts(results[type], match[1])
      end
    end

    [ results[:scenarios], results[:steps] ]
  end

  def self.parse_status_counts(results, status_counts)
    status_counts.split(', ').each do |part|
      results.keys.each do |key|
        results[key] += part.split.first.to_i if part.include?(key.to_s)
      end
    end
  end

  def self.file_pattern
    '**/**/*.feature'
  end
end
