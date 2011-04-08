require File.dirname(__FILE__) + '/rspec_adapter'
require File.dirname(__FILE__) + '/rspec2_adapter'
require File.dirname(__FILE__) + '/cucumber_adapter'
require File.dirname(__FILE__) + '/test_unit_adapter'

class Adapter
  def self.all
    [ RSpecAdapter, RSpec2Adapter, CucumberAdapter, TestUnitAdapter ]
  end

  def self.find(type)
    case type.to_sym
    when :rspec
      RSpec2Adapter
    when :spec
      RSpecAdapter
    when :features
      CucumberAdapter
    when :test
      TestUnitAdapter
    else
      raise "Unknown adapter: #{type}"
    end
  end
end
