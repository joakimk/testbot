require File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/shared/adapters/cucumber_adapter.rb'))
require 'test/unit'
require 'shoulda'

class CucumberAdapterTest < Test::Unit::TestCase

  context "sum_results" do
    
    should "be able to parse and sum results" do
      results =<<STR
testbot4:/tmp/testbot
............................................................................................................................................................

13 scenarios (\033[32m13 passed\033[0m)
153 steps (\033[32m153 passed\033[0m)
0m25.537s

testbot3:/tmp/testbot
................................................................................................................

12 scenarios (\033[32m12 passed\033[0m)
109 steps (\033[32m109 passed\033[0m)
1m28.472s
STR

      assert_equal "25 scenarios (25 passed)\n262 steps (262 passed)", Color.strip(CucumberAdapter.sum_results(results))
    end


    should "should handle undefined steps" do
      results =<<STR
5 scenarios (1 failed, 1 undefined, 3 passed)
42 steps (1 failed, 3 skipped, 1 undefined, 37 passed)

5 scenarios (1 failed, 1 undefined, 3 passed)
42 steps (1 failed, 3 skipped, 1 undefined, 37 passed)

6 scenarios (6 passed)
80 steps (80 passed)
STR

      assert_equal "16 scenarios (2 failed, 2 undefined, 12 passed)\n164 steps (2 failed, 6 skipped, 2 undefined, 154 passed)", Color.strip(CucumberAdapter.sum_results(results))
    end

    should "handle other combinations" do
      results =<<STR
5 scenarios (1 failed, 1 undefined, 3 passed)
42 steps (1 failed, 1 undefined, 37 passed)

5 scenarios (1 failed, 1 undefined, 3 passed)
42 steps (3 skipped, 1 undefined, 37 passed)

6 scenarios (6 passed)
80 steps (80 passed)
STR

      assert_equal "16 scenarios (2 failed, 2 undefined, 12 passed)\n164 steps (1 failed, 3 skipped, 2 undefined, 154 passed)", Color.strip(CucumberAdapter.sum_results(results))
    end

    should "colorize" do
      results =<<STR
5 scenarios (1 failed, 1 undefined, 3 passed)
42 steps (1 failed, 3 skipped, 1 undefined, 37 passed)
STR

      assert_equal "5 scenarios (\e[31m1 failed\e[0m, \e[33m1 undefined\e[0m, \e[32m3 passed\e[0m)\n42 steps (\e[31m1 failed\e[0m, \e[36m3 skipped\e[0m, \e[33m1 undefined\e[0m, \e[32m37 passed\e[0m)", CucumberAdapter.sum_results(results)
    end

  end


end
