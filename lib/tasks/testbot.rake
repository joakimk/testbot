namespace :testbot do
  desc "Run tests ..."
  task :spec do
    require File.join(File.dirname(__FILE__), '..', "new_requester.rb")
    requester = NewRequester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")
    requester.run_tests(:rspec, "#{RAILS_ROOT}/spec")
  end
end
