desc 'Runs the tests after each change'
task 'autotest' do
  system "/usr/bin/kicker --no-growl -e 'ruby test/server_test.rb; ruby test/new_runner_test.rb; ruby test/new_requester_test.rb' ."
end

task 'default' do
  ruby "test/server_test.rb"
  ruby "test/new_runner_test.rb"
  ruby "test/new_requester_test.rb"
  ruby "test/integration_test.rb" unless ENV['RUN_CODE_RUN']
end