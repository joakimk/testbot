require File.join(File.dirname(__FILE__), '../../lib/adapters/adapter.rb')
require 'test/unit'
require 'shoulda'

class AdapterTest < Test::Unit::TestCase
  
  should "be able to find the adapters" do
    assert_equal RSpecAdapter, Adapter.find(:rspec)
    assert_equal CucumberAdapter, Adapter.find(:cucumber)
    assert_equal TestUnitAdapter, Adapter.find(:test)
  end
  
  should "find be able to find an adapter by string" do
    assert_equal RSpecAdapter, Adapter.find("rspec") 
  end
  
end
