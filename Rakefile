desc 'Runs the tests after each change'
task 'autotest' do
  system "/usr/bin/kicker --no-growl -e 'ruby test/*_test.rb' ."
end

task 'default' do
  system "ruby test/*_test.rb"
end