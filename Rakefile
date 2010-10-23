task :default do
  Dir["test/**/test_*.rb"].each { |test| require(test) }
end

namespace :test do

  task :create_test_app do
    system "cd /tmp; rm -rf testapp; rails testapp &> /dev/null"
  
    print "Creating testgroups (100): "
    0.upto(100) do |number|
      print "#{number} "; STDOUT.flush
      system "cd /tmp/testapp; script/generate scaffold model#{number} field:string &> /dev/null"
    end
    puts
  
    system "cd /tmp/testapp; rake db:migrate &> /dev/null"
    puts "Testapp ready in /tmp/testapp"
  end
  
end
