require File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/shared/adapters/adapter.rb'))
require 'test/unit'
require 'shoulda'

class AdapterTest < Test::Unit::TestCase
  
  should "be able to find adapters" do
    assert_equal RspecAdapter, Adapter.find(:spec)
    assert_equal TestUnitAdapter, Adapter.find(:test)
  end
  
  should "find be able to find an adapter by string" do
    assert_equal RspecAdapter, Adapter.find("spec") 
    assert_equal TestUnitAdapter, Adapter.find("test") 
  end
  
  should "be able to return a list of adapters" do
    assert Adapter.all.include?(RspecAdapter)
    assert Adapter.all.include?(TestUnitAdapter)
  end
  
end
