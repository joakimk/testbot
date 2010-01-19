desc 'Runs the tests after each change'
task 'autotest' do
  system "/usr/bin/kicker --no-growl -e 'ruby test/server_test.rb test/integration_test.rb' ."
end

task 'default' do
  system "ruby test/server_test.rb test/integration_test.rb"
end