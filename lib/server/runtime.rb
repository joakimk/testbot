require 'rubygems'

class Runtime
  
  def self.build_groups(files, instances)
    files_per_group = (files.size / instances.to_f).ceil

    groups = []
    group = []
    files.each_with_index do |file, i|
      group << file
      if group.size == files_per_group || (files.size - 1 == i)
        groups << group
        group = []
      end
    end
    
    groups
  end
  
end