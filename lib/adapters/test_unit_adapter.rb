class TestUnitAdapter
  
  def self.command(files)
    "ruby -Itest -e '%w(#{files}).each { |file| require(file) }'"
  end
  
  def self.file_pattern
    '**/**/*_test.rb'
  end
  
  def self.requester_port
    2231
  end
  
end
