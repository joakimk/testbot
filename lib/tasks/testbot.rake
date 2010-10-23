namespace :testbot do
  
  TYPES = {
    :rspec => "specs",
    :cucumber => "features",
    :test => "tests"
  }
  
  def run_and_show_results(type, base_path, custom_path)
    Rake::Task["testbot:before_request"].invoke
    
    require File.join(File.dirname(__FILE__), '..', "requester.rb")
    requester = Requester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")

    puts "Running #{TYPES[type]}..."
    start_time = Time.now
    
    path = custom_path ? "#{base_path}/#{custom_path}" : base_path
    success = requester.run_tests(type, path)
    
    puts
    puts requester.result_lines.join("\n")
    puts
    puts "Finished in: #{Time.now - start_time} seconds."
    success
  end
    
  desc "Run the RSpec tests using testbot"
  task :spec, :custom_path do |_, args|
    exit 1 unless run_and_show_results(:rspec, 'spec', args[:custom_path])
  end
  
  desc "Run the Cucumber features using testbot"
  task :features, :custom_path do |_, args|
    exit 1 unless run_and_show_results(:cucumber, 'features', args[:custom_path])
  end  

  desc "Run the Test::Unit tests using testbot"
  task :test, :custom_path do |_, args|
    exit 1 unless run_and_show_results(:test, 'test', args[:custom_path])
  end
end
