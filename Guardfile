guard 'test', :all_after_pass => false, :all_on_start => false do
  watch(%r{^lib/(.+)\.rb$})     { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^test/.+_test\.rb$})
end

guard 'rspec', :all_after_pass => false, :all_on_start => false, :version => 2 do
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')  { "rspec" }
end
