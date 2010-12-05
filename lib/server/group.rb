require 'rubygems'

module Testbot::Server

  class Group

    DEFAULT = nil

    def self.build(files, sizes, instance_count, type)
      tests_with_sizes = slow_tests_first(map_files_and_sizes(files, sizes))

      groups = []
      current_group, current_size = 0, 0
      tests_with_sizes.each do |test, size|
        # inserts into next group if current is full and we are not in the last group
        if (0.5*size + current_size) > group_size(tests_with_sizes, instance_count) and instance_count > current_group + 1
          current_size = size
          current_group += 1
        else
          current_size += size
        end
        groups[current_group] ||= []
        groups[current_group] << test
      end

      groups.compact
    end

    private

    def self.group_size(tests_with_sizes, group_count)
      total = tests_with_sizes.inject(0) { |sum, test| sum += test[1] }
      total / group_count.to_f
    end

    def self.map_files_and_sizes(files, sizes)
      list = []
      files.each_with_index { |file, i| list << [ file, sizes[i] ] }
      list
    end

    def self.slow_tests_first(tests)
      tests.sort_by { |test, time| time.to_i }.reverse
    end

  end

end
