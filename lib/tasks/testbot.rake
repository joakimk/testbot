require File.dirname(__FILE__) + '/../adapters/adapter'

namespace :testbot do
  
  def run_and_show_results(adapter, custom_path)
    Rake::Task["testbot:before_request"].invoke
        
    require File.join(File.dirname(__FILE__), '..', "requester.rb")
    requester = Requester.create_by_config("#{RAILS_ROOT}/config/testbot.yml")

    puts "Running #{adapter.pluralized}..."
    start_time = Time.now
    
    path = custom_path ? "#{adapter.base_path}/#{custom_path}" : adapter.base_path
    success = requester.run_tests(adapter, path)
    
    puts
    puts requester.result_lines.join("\n")
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
