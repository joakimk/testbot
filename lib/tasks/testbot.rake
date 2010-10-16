namespace :testbot do
  
  def run_and_show_results(requester, type, path)
    puts "Running #{type} tests..."
    start_time = Time.now
    success = requester.run_tests(type, path)
    puts
    puts requester.result_lines.join("\n")
    puts
    puts "Finished in: #{Time.now - start_time} seconds."
    success
  end
  
  desc "Run the rspec tests using testbot"
  task :spec do
    require File.join(File.dirname(__FILE__), '..', "new_requester.rb")
    requester = NewRequester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    fail unless run_and_show_results(requester, :rspec, 'spec')
  end
  
  desc "Run the cucumber features using testbot"
  task :features do
    require File.join(File.dirname(__FILE__), '..', "new_requester.rb")
    requester = NewRequester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    fail unless run_and_show_results(requester, :cucumber, 'features')
  end  
end
