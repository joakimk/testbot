class RSpecAdapter
  
  def self.command(files)
    "export RSPEC_COLOR=true; script/spec -O spec/spec.opts #{files}"
  end
  
  def self.file_pattern
    '**/**/*_spec.rb'
  end
  
  def self.requester_port
    2299
  end
  
end
