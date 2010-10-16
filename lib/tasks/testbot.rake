namespace :testbot do
  desc "Run the rspec tests using testbot"
  task :spec do
    require File.join(File.dirname(__FILE__), '..', "new_requester.rb")
    requester = NewRequester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    
    puts "Running specs..."
    start_time = Time.now
    success = requester.run_tests(:rspec, "spec")
    puts
    puts "Finished in: #{Time.now - start_time} seconds."
    fail unless success
  end
end
