class Build < Sequel::Model

  def self.create_and_build_jobs(hash)
    build = create(hash.reject { |k, v| k == 'available_runner_usage' })
    build.create_jobs!(hash['available_runner_usage'])
    build
  end
  
  def create_jobs!(available_runner_usage)
    groups = Group.build(self[:files].split, self[:sizes].split.map { |size| size.to_i },
                     Runner.total_instances.to_f * (available_runner_usage.to_i / 100.0), self[:type])
    groups.each do |group|
      Job.create(:files => group.join(' '),
                 :root => self[:root],
                 :project => self[:project],
                 :type => self[:type],
                 :server_type => self[:server_type],
                 :requester_mac => self[:requester_mac],
                 :build_id => self[:id])
    end
  end
  
  def destroy
    Job.filter([ 'build_id = ?', self[:id] ]).each { |job| job.destroy }
    super
  end
  
end
