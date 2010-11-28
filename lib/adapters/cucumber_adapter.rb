class CucumberAdapter
  
  def self.command(ruby_interpreter, files)
    "export AUTOTEST=1; #{ruby_interpreter} script/cucumber -f progress --backtrace -r features/support -r features/step_definitions #{files} -t ~@disabled_in_cruise"
  end
 
  def self.test_files(dir)
    features = Dir["#{dir}/#{file_pattern}"]

    scenario_pointers = []
    features.each do |feature|
      File.readlines(feature).each_with_index { |line, i|
        scenario_pointers << "#{feature}:#{i+1}" if line.include?("Scenario:")
      }
    end

   scenario_pointers
  end
  
  def self.get_sizes(scenario_pointers)
 #   return scenario_pointers.map { 1 }
 #   return scenario_pointers.map { |file| File.stat(file).size }
 
    file_contents = {}
    
    files = scenario_pointers.map { |file| file.split(':').first }.uniq
    files.each do |file|
      file_contents[file] = File.readlines(file)
    end

    sizes = []
    scenario_pointers.each do |sp|
      lines = file_contents[sp.split(":").first]
      lines_before_first_scenario = 0
      lines.each_with_index do |line, i|
        if line.include?('Scenario:')
          lines_before_first_scenario = i
          break
        end
      end

      scenario_line = sp.split(":").last.to_i - 1
      size = nil
      lines.each_with_index do |line, i|
        if i > scenario_line && lines[i].include?("Scenario:")
          size = i - scenario_line
        end
      end

      # Last scenario
      unless size
        size = lines.size - scenario_line - 1
      end

      sizes << lines_before_first_scenario + size
    end
    
    sizes
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

private

  def self.file_pattern
    '**/**/*.feature'
  end
end
