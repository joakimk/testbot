require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/shared/testbot.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/runner/safe_result_text.rb'))
require 'test/unit'
require 'shoulda'

module Testbot::Runner

  class SafeResultTextTest < Test::Unit::TestCase

    should "not break escape sequences" do
      assert_equal "^[[32m.^[[0m^[[32m.^[[0m", SafeResultText.clean("^[[32m.^[[0m^[[32m.^[[0m^[[32m.")
      assert_equal "^[[32m.^[[0m^[[32m.^[[0m", SafeResultText.clean("^[[32m.^[[0m^[[32m.^[[0m^[[3")
      assert_equal "^[[32m.^[[0m", SafeResultText.clean("^[[32m.^[[0m^[")
      assert_equal "[32m.[0m[32m.[0m[3", SafeResultText.clean("[32m.[0m[32m.[0m[3")
      assert_equal "...", SafeResultText.clean("...")
    end

  end

end
