FAST_TESTS = [ "test/server_test.rb", "test/new_runner_test.rb", "test/requester_test.rb",
               "test/server/runtime_test.rb" ]
FAST_TESTS_CMD = "ruby #{FAST_TESTS.join('; ruby ')}"

desc 'Runs the tests after each change'
task 'autotest' do
  system "/usr/bin/kicker --no-growl -e '#{FAST_TESTS_CMD}' ."
end

task 'default' do
  system FAST_TESTS_CMD
  ruby "test/integration_test.rb" unless ENV['RUN_CODE_RUN']
end