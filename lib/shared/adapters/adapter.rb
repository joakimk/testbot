class Adapter

  FILES = Dir[File.dirname(__FILE__) + "/*_adapter.rb"]
  FILES.each { |file| require(file) }

  def self.all
    FILES.map { |file| load_adapter(file)  }
  end

  def self.find(type)
    if adapter = all.find { |adapter| adapter.type == type.to_s }
      adapter
    else
      raise "Unknown adapter: #{type}"
    end
  end

  private

  def self.load_adapter(file)
    eval("::" + File.basename(file).
         gsub(/\.rb/, '').
         gsub(/(?:^|_)(.)/) { $1.upcase })
  end

end

