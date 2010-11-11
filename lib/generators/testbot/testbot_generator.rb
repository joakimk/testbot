class TestbotGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  
  argument :project, :type => :string, :default => 'project'
  class_option :connect, :type => :string, :required => true, :desc => "Which server to use (required)"
  class_option :server_path, :type => :string, :default => nil, :desc => "Sync path on the server (default: #{Testbot::DEFAULT_SERVER_PATH})"  
  class_option :ignores, :type => :string, :default => nil, :desc => "Files to ignores when syncing (default: include all)"
  class_option :ssh_tunnel, :type => :string, :default => nil, :desc => "Use a ssh tunnel (format: user@server)"

  def generate_config
    template "testbot.yml.erb", "config/testbot.yml"
  end
end
