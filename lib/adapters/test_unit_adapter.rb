class TestUnitAdapter
  
  def self.command(ruby_interpreter, files)
    "#{ruby_interpreter} -Itest -e '%w(#{files}).each { |file| require(file) }'"
  end
  
  def self.test_files(dir)
    Dir["#{dir}/#{file_pattern}"]
  end

  def self.find_sizes(files)
    files.map { |file| File.stat(file).size }
  end
  
  def self.requester_port
    2231
  end
  
  def self.pluralized
    'tests'
  end
  
  def self.base_path
    type
  end
  
  def self.name
    'Test::Unit'
  end
  
  def self.type
    'test'
  end  
  
private

  def self.file_pattern
    '**/**/*_test.rb'
  end
  
end
