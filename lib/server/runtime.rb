require 'rubygems'
require File.join(File.dirname(__FILE__), '../db.rb')

class Runtime < Sequel::Model
  
  DEFAULT = nil
  
  def self.build_groups(files, instance_count, type)
    update_db(files, type)
    
    tests_with_times = slow_tests_first(find_tests_with_times(type))

    groups = []
    current_group, current_time = 0, 0
    tests_with_times.each do |test, time|
      # inserts into next group if current is full and we are not in the last group
      if (0.5*time + current_time) > group_time(tests_with_times, instance_count) and instance_count > current_group + 1
        current_time = time
        current_group += 1
      else
        current_time += time
      end
      groups[current_group] ||= []
      groups[current_group] << test
    end
    
    groups.compact
  end
  
  def self.store_results(files, total_time, type)
    # Disabled until we can find a way that actually works.
    # We might need to profile the machines that run the code so that we can
    # compute a better job size for them.
    
    # average = total_time / files.size.to_f
    # filter("type = '#{type}' AND path IN ('#{files.join("','")}')").each do |runtime|  
    #   if runtime.time
    #     new_runtime = runtime.time + ((average - runtime.time) / 4.0)
    #     runtime.update(:time => new_runtime.to_i)
    #   else
    #     runtime.update(:time => average.to_i)
    #   end
    # end
  end
  
  private
  
  def self.group_time(tests_with_times, group_count)
    total = tests_with_times.inject(0) { |sum, test| sum += test[1] }
    total / group_count.to_f
  end
  
  def self.slow_tests_first(tests)
    tests.sort_by { |test, time| time.to_i }.reverse
  end
  
  def self.find_tests_with_times(type)
    filter(:type => type).map { |runtime| [ runtime[:path], (runtime[:time] ? runtime[:time] : 1) ] }
  end
  
  def self.update_db(files, type)
    average = average(type)
    files.each do |path|
      unless find(:type => type, :path => path)
        create(:type => type, :path => path, :time => (average == 0 ? DEFAULT : average))
      end
    end
    
    filter(:type => type).each do |runtime|
      runtime.destroy unless files.include?(runtime.path)
    end
  end
  
  def self.average(type)
     DB.fetch("SELECT avg(time) FROM runtimes WHERE type = '#{type}'") do |row|
        return row.first[1].to_i
     end
   end
  
end