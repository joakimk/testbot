require File.dirname(__FILE__) + '/../shared/adapters/adapter'

namespace :testbot do
  
  def run_and_show_results(adapter, custom_path)
    Rake::Task["testbot:before_request"].invoke
        
    require File.expand_path(File.join(File.dirname(__FILE__), '..', 'requester', 'requester.rb'))
    requester = Testbot::Requester::Requester.create_by_config("#{Rails.root}/config/testbot.yml")

    puts "Running #{adapter.pluralized}..."
    start_time = Time.now
    
    path = custom_path ? "#{adapter.base_path}/#{custom_path}" : adapter.base_path
    success = requester.run_tests(adapter, path)
    
    puts
    puts "Finished in #{Time.now - start_time} seconds."
    success
  end
  
  Adapter.all.each do |adapter|

    desc "Run the #{adapter.name} tests using testbot"
    task adapter.type, :custom_path do |_, args|
      exit 1 unless run_and_show_results(adapter, args[:custom_path])
    end
    
  end
end
