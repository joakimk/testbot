require File.join(File.dirname(__FILE__), '../../lib/server/group')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class GroupTest < Test::Unit::TestCase
  
  context "self.build" do
    
    should "create file groups based on the number of instances" do
      groups = Group.build([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], [ 1, 1, 1, 1 ], 2, 'spec')

      assert_equal 2, groups.size
      assert_equal [ 'spec/models/house2_spec.rb', 'spec/models/house_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/car2_spec.rb', 'spec/models/car_spec.rb' ], groups[1]
    end

    should "create a small grop when there isn't enough specs to fill a normal one" do
      groups = Group.build(["spec/models/car_spec.rb", "spec/models/car2_spec.rb",   
                                     "spec/models/house_spec.rb", "spec/models/house2_spec.rb",
                                     "spec/models/house3_spec.rb"], [ 1, 1, 1, 1, 1 ], 3, 'spec')
      
      assert_equal 3, groups.size
      assert_equal [ "spec/models/car_spec.rb" ], groups[2]
    end
    
    should "use sizes when building groups" do
      groups = Group.build([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], [ 40, 10, 10, 20 ], 2, 'spec')
    
      assert_equal [ 'spec/models/car_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/house2_spec.rb', 'spec/models/car2_spec.rb', 'spec/models/house_spec.rb' ], groups[1]      
    end
    
  end

end