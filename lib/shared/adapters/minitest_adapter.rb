require File.expand_path(File.join(File.dirname(__FILE__), "/helpers/ruby_env"))

class MinitestAdapter

  def self.command(project_path, ruby_interpreter, files)
    ruby_command = RubyEnv.ruby_command(project_path, :ruby_interpreter => ruby_interpreter)
    %{#{ruby_command} -I#{base_path} -e '%w(#{files}).each { |file| require(Dir.pwd + "/" + file) }'}
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
    'tests'
  end

  def self.base_path
    "test"
  end

  def self.name
    'Minitest'
  end

  def self.type
    'minitest'
  end

private

  def self.file_pattern
    '**/**/*_test.rb'
  end

end
