require File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib/shared/adapters/helpers/ruby_env.rb'))
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

  context "self.ruby_command" do
    
    should "use ruby by default" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(false)
      flexmock(File).should_receive(:exists?).and_return(false)
      assert_equal 'ruby -S rspec', RubyEnv.ruby_command("path/to/project", :script => "script/spec", :bin => "rspec")
    end
    
    should "use bundler when available and use the binary when there is no script" do
      flexmock(RubyEnv).should_receive(:bundler?).once.with("path/to/project").and_return(true)
      flexmock(File).should_receive(:exists?).with("path/to/project/script/spec").and_return(false)
      assert_equal 'ruby -S bundle exec rspec', RubyEnv.ruby_command("path/to/project", :script => "script/spec", :bin => "rspec")  
    end

    should "use the script when it exists when using bundler" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(true)
      flexmock(File).should_receive(:exists?).and_return(true)
      assert_equal 'ruby -S bundle exec script/spec', RubyEnv.ruby_command("path/to/project", :script => "script/spec", :bin => "rspec")  
    end

    should "use the script when it exists when not using bundler" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(false)
      flexmock(File).should_receive(:exists?).and_return(true)
      assert_equal 'ruby -S script/spec', RubyEnv.ruby_command("path/to/project", :script => "script/spec", :bin => "rspec")  
    end

    should "not look for a script when none is provided" do
      flexmock(File).should_receive(:exists?).once # Once for bundler check
      assert_equal 'ruby -S rspec', RubyEnv.ruby_command("path/to/project", :bin => "rspec")  
    end

    should "be able to use jruby" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(false)
      flexmock(File).should_receive(:exists?).and_return(true)
      assert_equal 'jruby -S script/spec', RubyEnv.ruby_command("path/to/project", :script => "script/spec",
                                                                :bin => "rspec", :ruby_interpreter => "jruby")
    end

    should "be able to use jruby with bundler" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(true)
      flexmock(File).should_receive(:exists?).and_return(true)
      assert_equal 'jruby -S bundle exec script/spec', RubyEnv.ruby_command("path/to/project", :script => "script/spec",
                                                                            :bin => "rspec", :ruby_interpreter => "jruby")
    end

    should "work when there is no binary specified and bundler is present" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(true)
      flexmock(File).should_receive(:exists?).and_return(false)
      assert_equal 'ruby -S bundle exec', RubyEnv.ruby_command("path/to/project")
    end

    should "work when there is no binary specified and bundler is not present" do
      flexmock(RubyEnv).should_receive(:bundler?).and_return(false)
      flexmock(File).should_receive(:exists?).and_return(false)
      assert_equal 'ruby -S', RubyEnv.ruby_command("path/to/project")
    end


  end

end
