require File.expand_path(File.dirname(__FILE__) + "/../../testbot") 

module Testbot
  DESC = {
    :connect => "Which server to use (required)",
    :project => "The name of your project (default: #{Testbot::DEFAULT_PROJECT})",
    :rsync_path => "Sync path on the server (default: #{Testbot::DEFAULT_SERVER_PATH})"
  }
end

# Rails 3
if defined?(Rails::Generators::Base) 
  class TestbotGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    class_option :connect, :type => :string, :required => true, :desc => Testbot::DESC[:connect] 
    class_option :project, :type => :string, :default => nil, :desc => Testbot::DESC[:project] 
    class_option :rsync_path, :type => :string, :default => nil, :desc => Testbot::DESC[:rsync_path]
    class_option :rsync_ignores, :type => :string, :default => nil, :desc => "Files to rsync_ignores when syncing (default: include all)"
    class_option :ssh_tunnel, :type => :boolean, :default => nil, :desc => "Use a ssh tunnel"
    class_option :user, :type => :string, :default => nil, :desc => "Use a custom rsync / ssh tunnel user (default: #{Testbot::DEFAULT_USER})"
  
    def generate_config
      template "testbot.yml.erb", "config/testbot.yml"
      template "testbot.rake.erb", "lib/tasks/testbot.rake"
    end
  end
else # Rails 2
  class TestbotGenerator < Rails::Generator::Base

    def manifest
      record do |m|
        m.template "testbot.rake.erb", "lib/tasks/testbot.rake"
        m.template "testbot.yml.erb", "config/testbot.yml"
      end
    end

    private

    def add_options!(opt)
      opt.on('--connect HOST', Testbot::DESC[:connect]) { |v| options[:connect] = v } # TODO: REQ
      opt.on('--project NAME', Testbot::DESC[:project]) { |v| options[:project] = v }
    end

  end
end

