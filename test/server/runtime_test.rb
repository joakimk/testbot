require File.join(File.dirname(__FILE__), '../../lib/server/runtime')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class RuntimeTest < Test::Unit::TestCase

  context "self.build_groups" do
    
    should "create file groups based on the number of instances" do
      groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2)

      assert_equal 2, groups.size
      assert_equal [ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], groups[1]
    end
    
  end

end