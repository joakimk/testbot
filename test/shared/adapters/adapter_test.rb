require File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/shared/adapters/adapter.rb'))
require 'test/unit'
require 'shoulda'

class AdapterTest < Test::Unit::TestCase
  
  should "be able to find adapters" do
    assert_equal RspecAdapter, Adapter.find(:spec)
    assert_equal MinitestSpecAdapter, Adapter.find(:minitest_spec)
    assert_equal TestUnitAdapter, Adapter.find(:test)
    assert_equal MinitestAdapter, Adapter.find(:minitest)
  end
  
  should "find be able to find an adapter by string" do
    assert_equal RspecAdapter, Adapter.find("spec") 
    assert_equal MinitestSpecAdapter, Adapter.find("minitest_spec")
    assert_equal MinitestAdapter, Adapter.find("minitest")
    assert_equal TestUnitAdapter, Adapter.find("test")
  end
  
  should "be able to return a list of adapters" do
    assert Adapter.all.include?(RspecAdapter)
    assert Adapter.all.include?(TestUnitAdapter)
    assert Adapter.all.include?(MinitestAdapter)
    assert Adapter.all.include?(MinitestSpecAdapter)
  end
  
end
