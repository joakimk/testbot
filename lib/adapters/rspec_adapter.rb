class RSpecAdapter
  
  def self.command(ruby_interpreter, files)
    "export RSPEC_COLOR=true; #{ruby_interpreter} script/spec -O spec/spec.opts #{files}"
  end
  
  def self.file_pattern
    '**/**/*_spec.rb'
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
  
end
