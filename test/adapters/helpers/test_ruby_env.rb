require File.join(File.dirname(__FILE__), '../../../lib/adapters/helpers/ruby_env.rb')
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

class RubyEnvTest < Test::Unit::TestCase
  
  context "self.bundler?" do

    should "return true if bundler is installed and there is a Gemfile" do
      flexmock(Gem).should_receive(:available?).with("bundler").once.and_return(true)
      flexmock(File).should_receive(:exists?).with("path/to/project/Gemfile").once.and_return(true)
      assert_equal true, RubyEnv.bundler?("path/to/project")
    end

    should "return false if bundler is installed but there is no Gemfile" do
      flexmock(Gem).should_receive(:available?).with("bundler").once.and_return(true)
      flexmock(File).should_receive(:exists?).and_return(false)
      assert_equal false, RubyEnv.bundler?("path/to/project")
    end

    should "return false if bundler is not installed" do
      flexmock(Gem).should_receive(:available?).with("bundler").once.and_return(false)
      assert_equal false, RubyEnv.bundler?("path/to/project")
    end

  end

end
