require File.join(File.dirname(__FILE__), '../../lib/server/runtime')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class RuntimeTest < Test::Unit::TestCase

  def setup
    DB[:runtimes].delete
  end
  
  context "self.build_groups" do
    
    should "create file groups based on the number of instances" do
      groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')

      assert_equal 2, groups.size
      assert_equal [ 'spec/models/house2_spec.rb', 'spec/models/house_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/car2_spec.rb', 'spec/models/car_spec.rb' ], groups[1]
    end

    should "create a small grop when there isn't enough specs to fill a normal one" do
      groups = Runtime.build_groups(["spec/models/car_spec.rb", "spec/models/car2_spec.rb",   
                                     "spec/models/house_spec.rb", "spec/models/house2_spec.rb",
                                     "spec/models/house3_spec.rb"], 3, 'spec')
      
      assert_equal 3, groups.size
      assert_equal [ "spec/models/car_spec.rb" ], groups[2]
    end

    should "remove files in the database that isn't present now" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')
                             
     Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                            'spec/models/house_spec.rb' ], 2, 'spec')
      
      assert_equal 3, Runtime.filter([ 'type = ?', 'spec' ]).count
      assert_equal nil, Runtime.find([ 'path = ?', 'spec/models/house2_spec.rb' ])
    end
    
    should "set time to the average for new files" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb' ], 2, 'spec')
      first, second = Runtime.all
      
      first.update(:time => 30)
      second.update(:time => 10)

      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb'], 2, 'spec')
      
      r1, r2, r3 = Runtime.all
      assert_equal 30, r1.time
      assert_equal 10, r2.time
      assert_equal 20, r3.time
    end
    
    should "use times when building groups" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')
      
      Runtime.first.update(:time => 40)
      groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')
      
      assert_equal [ 'spec/models/car_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/house_spec.rb', 'spec/models/car2_spec.rb', 'spec/models/house2_spec.rb' ], groups[1]
    end
    
  end
  
  context "self.store_results" do
    
    # should "update times on files based on the job completion time" do
    #   groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
    #                                   'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')
    # 
    #    Runtime.store_results(groups.first, 100, 'spec')
    #   
    #    r1, r2, r3, r4 = Runtime.all
    #    assert_equal groups.first[1], r3.path
    #    assert_equal groups.first[0], r4.path
    #    assert_equal 50, r3.time
    #    assert_equal 50, r4.time
    # 
    #    # Defaults
    #    assert_equal Runtime::DEFAULT, r1.time
    #    assert_equal Runtime::DEFAULT, r2.time
    # end
    
    # should "increase or decrease the files times but not entirely reset them" do
    #   groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
    #                                   'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'spec')
    # 
    #   r1, r2, r3, r4 = Runtime.all
    #   
    #   # Group 1
    #   r3.update(:time => 50)
    #   r4.update(:time => 50)
    # 
    #   # Group 2
    #   r1.update(:time => 150)
    #   r2.update(:time => 150)
    #   
    #   # 200 / 2 instances = 100
    #   Runtime.store_results(groups.first, 200, 'spec')
    #   Runtime.store_results(groups.last, 200, 'spec')
    # 
    #   r1, r2, r3, r4 = Runtime.all
    #   
    #   # Group 1 (Old: 100, New: 125)
    #   assert_equal 62, r3.time # 50 + ((200/2 - 50) / 4.0)
    #   assert_equal 62, r4.time # 50 + ((200/2 - 50) / 4.0)
    #   
    #   # Group 2 (Old: 300, New: 275)
    #   assert_equal 137, r1.time # 150 + ((200/2 - 150) / 4.0)
    #   assert_equal 137, r2.time # 150 + ((200/2 - 150) / 4.0)
    # end
    
  end

end