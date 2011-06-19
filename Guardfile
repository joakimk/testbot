# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'test', :all_after_pass => false, :all_on_start => false do
  watch(%r{^lib/(.+)\.rb$})     { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^test/.+_test\.rb$})
end
