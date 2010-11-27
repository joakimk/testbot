class CucumberAdapter
  
  def self.command(ruby_interpreter, files)
    "export AUTOTEST=1; #{ruby_interpreter} script/cucumber -f progress --backtrace -r features/support -r features/step_definitions #{files} -t ~@disabled_in_cruise"
  end
 
  def self.test_files(dir)
    Dir["#{dir}/#{file_pattern}"]
  end
  
  def self.find_sizes(files)
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

private

  def self.file_pattern
    '**/**/*.feature'
  end
end
