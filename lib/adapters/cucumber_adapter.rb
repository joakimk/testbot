class CucumberAdapter
  
  def self.command(files)
    "export AUTOTEST=1; script/cucumber -f progress --backtrace -r features/support -r features/step_definitions #{files} -t ~@disabled_in_cruise"
  end
  
  def self.file_pattern
    '**/**/*.feature'
  end
  
  def self.requester_port
    2230
  end
  
  def self.pluralized
    'features'
  end
  
  def self.base_path
    'features'
  end
  
  def self.name
    'Cucumber'
  end
  
  def self.type
    :cucumber
  end
  
end
