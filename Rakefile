desc 'Runs the tests after each change'
task 'autotest' do
  system "/usr/bin/kicker --no-growl -e 'ruby *_test.rb' ."
end

task 'default' do
  system "ruby *_test.rb"
end