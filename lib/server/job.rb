module Testbot::Server

  class Job < MemoryModel
   
    attribute :success, :boolean

    def update(hash)
      super(hash)
      if self.build
        done = !Job.all.find { |j| !j.result && j.build == self.build }
        self.build.update(:results => build.results.to_s + self.result.to_s,
                          :done => done)

        build_broken_by_job = (!self.success && build.success)
        self.build.update(:success => false) if build_broken_by_job
      end
    end

    def self.next(params, remove_addr)
      clean_params = params.reject { |k, v| [ "requester_mac", "no_jruby" ].include?(k) }
      runner = Runner.record! clean_params.merge({ :ip => remove_addr, :last_seen_at => Time.now })
      return unless Server.valid_version?(params[:version])
      [ next_job(params["requester_mac"], params["no_jruby"]), runner ]
    end

    private

    def self.next_job(requester_mac, no_jruby)
      release_jobs_taken_by_missing_runners!
      jobs = Job.all.find_all { |j|
        !j.taken_at &&
          (requester_mac ? j.requester_mac == requester_mac : true) &&
          (no_jruby ? j.jruby != 1 : true)
      }

      jobs[rand(jobs.size)]
    end

    def self.release_jobs_taken_by_missing_runners!
      missing_runners = Runner.all.find_all { |r| r.last_seen_at < (Time.now - Runner.timeout) }
      missing_runners.each { |runner|
        Job.all.find_all { |job| job.taken_by == runner }.each { |job| job.update(:taken_at => nil) }
      }
    end
  end

end
