

class Build < Sequel::Model

  def self.create_and_build_jobs(hash)
    build = create(hash.reject { |k, v| k == 'available_runner_usage' })
    build.create_jobs!(hash['available_runner_usage'])
    build
  end
  
  def create_jobs!(available_runner_usage)
    groups = Runtime.build_groups(self[:files].split,
                     Runner.total_instances.to_f * (available_runner_usage.to_i / 100.0), self[:type])
    groups.each do |group|
      Job.create(:files => group.join(' '),
                 :root => self[:root],
                 :type => self[:type],
                 :server_type => self[:server_type],
                 :requester_mac => self[:requester_mac],
                 :build_id => self[:id])
    end
  end
  
end
