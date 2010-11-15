class TestbotGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  
  class_option :connect, :type => :string, :required => true, :desc => "Which server to use (required)"
  class_option :project, :type => :string, :default => nil, :desc => "The name of your project (default: #{Testbot::DEFAULT_PROJECT})"
  class_option :rsync_path, :type => :string, :default => nil, :desc => "Sync path on the server (default: #{Testbot::DEFAULT_SERVER_PATH})"  
  class_option :rsync_ignores, :type => :string, :default => nil, :desc => "Files to rsync_ignores when syncing (default: include all)"
  class_option :ssh_tunnel, :type => :boolean, :default => nil, :desc => "Use a ssh tunnel"
  class_option :user, :type => :string, :default => nil, :desc => "Use a custom rsync / ssh tunnel user (default: #{Testbot::DEFAULT_USER})"

  def generate_config
    template "testbot.yml.erb", "config/testbot.yml"
    template "testbot.rake.erb", "lib/tasks/testbot.rake"
  end
end
