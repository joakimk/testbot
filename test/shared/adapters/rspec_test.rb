require File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/shared/adapters/rspec_adapter.rb'))
require 'test/unit'
require 'shoulda'

class RspecAdapterTest < Test::Unit::TestCase
  
  context "sum_results" do

    should "be able to parse and sum results" do
      results =<<STR
srv-y5ei5:/tmp/testbot
..................FF..................................................

Finished in 4.962975 seconds

69 examples, 2 failures


testbot1:/tmp/testbot
.............F...........*........................

Finished in 9.987141 seconds

50 examples, 1 failure, 1 pending

testbot1:/tmp/testbot
.............FF.......****........................

Finished in 9.987141 seconds

50 examples, 2 failures, 3 pending

testbot1:/tmp/testbot
.

Finished in 9.987141 seconds

1 example, 0 failures, 0 pending
STR
      assert_equal "170 examples, 5 failures, 4 pending", RspecAdapter.sum_results(results) 
    end

    should "return 0 examples and failures for an empty resultset" do
      assert_equal "0 examples, 0 failures", RspecAdapter.sum_results("") 
    end
  end

end
