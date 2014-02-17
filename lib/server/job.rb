module Testbot::Server

  class Job < MemoryModel

    def update(hash)
      super(hash)
      if self.build
        self.done = done?
        done = !Job.all.find { |j| !j.done && j.build == self.build }
        self.build.update(:results => build_results(build), :done => done)

        build_broken_by_job = (self.status == "failed" && build.success)
        self.build.update(:success => false) if build_broken_by_job
      end
    end

    def self.next(params, remove_addr)
      clean_params = params.reject { |k, v| k == "no_jruby" }
      runner = Runner.record! clean_params.merge({ :ip => remove_addr, :last_seen_at => Time.now })
      return unless Server.valid_version?(params[:version])
      [ next_job(params["build_id"], params["no_jruby"]), runner ]
    end

    private

    def build_results(build)
      self.last_result_position ||= 0
      new_results = self.result.to_s[self.last_result_position..-1] || ""
      self.last_result_position = self.result.to_s.size

      # Don't know why this is needed as the job should cleanup
      # escape sequences.
      if new_results[0,4] == '[32m'
        new_results = new_results[4..-1]
      end

      build.results.to_s + new_results 
    end

    def done?
      self.status == "successful" || self.status == "failed"
    end

    def self.next_job(build_id, no_jruby)
      release_jobs_taken_by_missing_runners!
      jobs = Job.all.find_all { |j|
        !j.taken_at &&
          (build_id ? j.build.id.to_s == build_id : true) &&
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
