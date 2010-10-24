require File.join(File.dirname(__FILE__), '../../lib/adapters/adapter.rb')
require 'test/unit'
require 'shoulda'

class AdapterTest < Test::Unit::TestCase
  
  should "be able to find the adapters" do
    assert_equal RSpecAdapter, Adapter.find(:spec)
    assert_equal CucumberAdapter, Adapter.find(:features)
    assert_equal TestUnitAdapter, Adapter.find(:test)
  end
  
  should "find be able to find an adapter by string" do
    assert_equal RSpecAdapter, Adapter.find("spec") 
  end
  
  should "return be able to all types" do
    assert_equal [ RSpecAdapter, CucumberAdapter, TestUnitAdapter ], Adapter.all
  end
  
end
