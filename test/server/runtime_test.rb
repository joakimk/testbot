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
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')

      assert_equal 2, groups.size
      assert_equal [ 'spec/models/house2_spec.rb', 'spec/models/house_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/car2_spec.rb', 'spec/models/car_spec.rb' ], groups[1]
    end

    should "create a small grop when there isn't enough specs to fill a normal one" do
      groups = Runtime.build_groups(["spec/models/car_spec.rb", "spec/models/car2_spec.rb",   
                                     "spec/models/house_spec.rb", "spec/models/house2_spec.rb",
                                     "spec/models/house3_spec.rb"], 3, 'rspec')
      
      assert_equal 3, groups.size
      assert_equal [ "spec/models/car_spec.rb" ], groups[2]
    end
    
    should "save the files in a database and default time to 10 seconds when there isn't any times yet" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')
                            
      assert_equal 4, Runtime.filter([ 'type = ?', 'rspec' ]).count
      assert_equal 'spec/models/car_spec.rb', Runtime.first[:path]
      assert_equal 'rspec', Runtime.first[:type]
      assert_equal 10, Runtime.first[:time]
    end
    
    should "remove files in the database that isn't present now" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')
                             
     Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                            'spec/models/house_spec.rb' ], 2, 'rspec')
      
      assert_equal 3, Runtime.filter([ 'type = ?', 'rspec' ]).count
      assert_equal nil, Runtime.find([ 'path = ?', 'spec/models/house2_spec.rb' ])
    end
    
    should "set time to the average for new files" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb' ], 2, 'rspec')
      first, second = Runtime.all
      
      first.update(:time => 30)
      second.update(:time => 10)

      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb'], 2, 'rspec')
      
      r1, r2, r3 = Runtime.all
      assert_equal 30, r1.time
      assert_equal 10, r2.time
      assert_equal 20, r3.time
    end
    
    should "use times when building groups" do
      Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                             'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')
      
      Runtime.first.update(:time => 40)
      groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')
      
      assert_equal [ 'spec/models/car_spec.rb' ], groups[0]
      assert_equal [ 'spec/models/house_spec.rb', 'spec/models/car2_spec.rb', 'spec/models/house2_spec.rb' ], groups[1]
    end
    
  end
  
  context "self.store_results" do
    
    should "update times on files based on the job completion time" do
      groups = Runtime.build_groups([ 'spec/models/car_spec.rb', 'spec/models/car2_spec.rb',
                                      'spec/models/house_spec.rb', 'spec/models/house2_spec.rb' ], 2, 'rspec')

       Runtime.store_results(groups.first, 100, 'rspec')
      
       r1, r2, r3, r4 = Runtime.all
       assert_equal groups.first[1], r3.path
       assert_equal groups.first[0], r4.path
       assert_equal 50, r3.time
       assert_equal 50, r4.time

       # Defaults
       assert_equal Runtime::DEFAULT, r1.time
       assert_equal Runtime::DEFAULT, r2.time
    end
    
  end

end