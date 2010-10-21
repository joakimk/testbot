namespace :testbot do
  
  def run_and_show_results(requester, type, base_path, custom_path)
    puts "Running #{type} tests..."
    start_time = Time.now
    
    path = custom_path ? "#{base_path}/#{custom_path}" : base_path
    success = requester.run_tests(type, path)
    
    puts
    puts requester.result_lines.join("\n")
    puts
    puts "Finished in: #{Time.now - start_time} seconds."
    success
  end
  
  desc "Run the rspec tests using testbot"
  task :spec, :custom_path do |_, args|
    require File.join(File.dirname(__FILE__), '..', "requester.rb")
    requester = Requester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    exit 1 unless run_and_show_results(requester, :rspec, 'spec', args[:custom_path])
  end
  
  desc "Run the cucumber features using testbot"
  task :features, :custom_path do |_, args|
    require File.join(File.dirname(__FILE__), '..', "requester.rb")
    requester = Requester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    exit 1 unless run_and_show_results(requester, :cucumber, 'features', args[:custom_path])
  end  
end
