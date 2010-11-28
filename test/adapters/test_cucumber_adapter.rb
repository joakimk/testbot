require File.join(File.dirname(__FILE__), '../../lib/adapters/cucumber_adapter.rb')
require 'test/unit'
require 'shoulda'

class CucumberAdapterTest < Test::Unit::TestCase
  def setup
    @feature = <<FEATURE
Feature: User admin

  Background:
    Given there are some users
    And an admin is logged in

  Scenario: First scenario
    Given something
    Then something

  Scenario: Second scenario
    Given something
    And something
    Then something

")
FEATURE
  end

  context "test_files" do

    should "return pointers to each scenario in the files (to be able to decrease overall test runtime)" do
      test_dir = "tmp/cucumber_adapter_test"
      system "mkdir -p #{test_dir}"

      File.open("#{test_dir}/user_admin.feature", "w") { |f| f.write(@feature) }
      assert_equal [ "#{test_dir}/user_admin.feature:7", "#{test_dir}/user_admin.feature:11" ],
                   CucumberAdapter.test_files(test_dir)
    end

    # TODO: Handle non-english scenarios.

  end

  context "get_sizes" do

    should "return the size of the scenario and the background" do
      test_dir = "tmp/cucumber_adapter_test"
      system "mkdir -p #{test_dir}"

      File.open("#{test_dir}/user_admin.feature", "w") { |f| f.write(@feature) }
      assert_equal [ 10, 11 ],
                   CucumberAdapter.get_sizes([ "#{test_dir}/user_admin.feature:7", "#{test_dir}/user_admin.feature:11" ])
    end

  end

end

